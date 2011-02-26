#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010  Bouke Woudstra (boukewoudstra@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

# A class that interprets the toc with the info of cdparanoia
# It's purpose is pure for ripping the correct audio, not for
# creating the freedb string. Cd-info is better for that.
# Before ripping, the function checkOffsetFirstTrack should be called.
class ScanDiscCdparanoia

  # * preferences is an instance of Preferences
  # * fireCommand is an instance of FireCommand
  # * permissionDrive is an instance of PermissionDrive
  def initialize(fireCommand, permissionDrive)
    @fire = fireCommand
    @perm = permissionDrive

    @status = 'ok'
    @disc = Hash.new
    @disc['playtime'] = _('Unknown')
    @disc['audiotracks'] = 0
    @disc['startSector'] = Hash.new
    @disc['lengthSector'] = Hash.new
    @disc['lengthText'] = Hash.new
    @disc['dataTracks'] = Array.new
    @disc['multipleDriveSupport'] = true
  end

  # scan the disc for input
  def scan(cdrom, ripHiddenAudio, minLengthHiddenTrack)
    @cdrom = cdrom
    @ripHidden = ripHiddenAudio
    @minLength = minLengthHiddenTrack

    query = @fire.launch('cdparanoia', "cdparanoia -d #{@cdrom} -vQ 2>&1")

    # some versions of cdparanoia don't support the cdrom parameter
    if query.include?('USAGE')
      query = @fire.launch('cdparanoia', "cdparanoia -vQ 2>&1")
      @disc['multipleDriveSupport'] = false
    end

    if isValidQuery(query)
      parseQuery(query)
      addExtraInfo()
      checkOffsetFirstTrack()
    end

    if @status == 'ok'
      @status = @perm.checkPermission(@cdrom, query)
    end
  end

  # return the disc variable
  def get(key) ; return @disc[key] end

  # return the status, 'ok' is good
  def status ; return @status ; end

  # prepend the gaps, so rewrite the toc info
  # notice that cdparanoia appends by default
  # * scanCdrdao = instance of ScanDiscCdrdao
  def prependGaps(scanCdrdao)
    (2..@disc['audiotracks']).each do |track|
      pregap = scanCdrdao.getPregap(track)
      @disc['lengthSector'][track - 1] -= pregap
      @disc['startSector'][track] -= pregap
      @disc['lengthSector'][track] += pregap
    end
  end

  # return the startSector, example for track 1 getStartSector(1)
  # if image, return the start sector for the lowest tracknumber
  def getStartSector(track)
    case track
      when 'image' then @disc['startSector'][@disc['startSector'].keys.sort[0]]
      else @disc['startSector'][track]
    end
  end

  # return the sectors, example for track 1 getLengthSector(1)
  def getLengthSector(track)
    case track
      when 'image' then @disc['totalSectors']
      else @disc['lengthSector'][track]
    end
  end

  # return the length in text, example for track 1 getLengthSector(1)
  def getLengthText(track)
    case track
      when 'image' then @disc['playtime']
      else @disc['lengthText'][track]
    end
  end

  # return the length in bytes, example for track 1 getFileSize(1)
  def getFileSize(track)
    case track
      when 'image' then 44 + @disc['totalSectors'] * 2352
      else 44 + @disc['lengthSector'][track] * 2352
    end
  end

private

  # check the query result for errors
  def isValidQuery(query)
    if query.include?('Unable to open disc')
      @status = _("No disc found in drive %s.\n\n\
Please put an audio disc in first...") %[@cdrom]
    elsif query.include?('USAGE')
      @status = _('ERROR: %s doesn\'t recognize the parameters.') %['Cdparanoia']
    elsif query.include?('No such file or directory')
      @status = _('ERROR: drive %s is not found') %[@cdrom]
    end

    return @status == 'ok'
  end

  # store the info of the query in variables
  def parseQuery(query)
    currentTrack = 0
    query.each_line do |line|
      if line[0,5] =~ /\s+\d+\./
        currentTrack += 1
        tracknumber, lengthSector, lengthText, startSector = line.split
        if currentTrack == 1
          @disc['firstAudioTrack'] = tracknumber[0..-2].to_i
        end
        @disc['lengthSector'][currentTrack] = lengthSector.to_i
        @disc['startSector'][currentTrack] = startSector.to_i
        @disc['lengthText'][currentTrack] = lengthText[1..-2]
      elsif line =~ /CDROM\D*:/
        @disc['devicename'] = $'.strip()
      elsif line[0,5] == "TOTAL"
        @disc['playtime'] = line.split()[2][1,5]
      end
    end
    @disc['audiotracks'] = currentTrack
  end

  # add some extra variables and add corrections
  def addExtraInfo
    if @disc['audioTracks'] == 0
      @status = _('ERROR: No audio tracks found!')
    end
    @disc['totalSectors'] = 0
    @disc['lengthSector'].each_value do |value|
      @disc['totalSectors'] += value
    end
  end

  # When a data track is the first track on a disc, cdparanoia is acting
  # strange: In the query it is showing as a start for 1s track the offset of
  # the data track. When ripping this offset isn't used however !! To allow
  # a correct rip of this disc all startSectors have to be corrected. See
  # also issue 196.

  # If there is no data track at the start, but we do have an offset this
  # means some hidden audio part. This part is marked as track 0. You can
  # only assess this on a cd-player by rewinding from 1st track on.
  def checkOffsetFirstTrack()
    # correct the startSectors when a disc starts with data
    if @disc['firstAudioTrack'] != 1
      dataOffset = @disc['startSector'][1]
      @disc['startSector'].each_key do |key, value|
        @disc['startSector'][key] -= dataOffset
      end
      #do nothing extra when hidden audio shouldn't be ripped
      #in the cuesheet this part will be marked as a pregap (silence).
    elsif @ripHidden == false
      # if size of hiddenAudio is bigger than minimum length, make track 0
    elsif (@disc['startSector'][1] != 0 &&
           @disc['startSector'][1] / 75.0 > @minLength)
      @disc['startSector'][0] = 0
      @disc['lengthSector'][0] = @disc['startSector'][1]
      # otherwise prepend it to the first track
    elsif @disc['startSector'][1] != 0
      @disc['lengthSector'][1] += @disc['startSector'][1]
      @disc['startSector'][1] = 0
    end
  end
end
