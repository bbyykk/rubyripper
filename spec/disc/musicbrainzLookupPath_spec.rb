#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2011  Ian Jacobi (pipian@pipian.com)
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

require 'rubyripper/disc/calcMusicbrainzID'

describe CalcMusicbrainzID do

  let(:disc) {double{'Disc'}.as_null_object}
  let(:scanner) {double{'AdvancedTocScanner'}.as_null_object}

  before(:each) do
    @musicbrainz = CalcMusicbrainzID.new(disc)
    @musicbrainzLookupPath = "discid/I5l9cCSFccLKFEKS.7wqSZAorPU-?toc=1+12+267257+150+22767+41887+58317+72102+91375+104652+115380+132165+143932+159870+174597"
  end

  context "Try to calculate MusicBrainz DiscID manually" do
    before(:each) do
      @start = {1=>0, 2=>22617, 3=>41737, 4=>58167, 5=>71952, 6=>91225,
7=>104502, 8=>115230, 9=>132015, 10=>143782, 11=>159720, 12=>174447, 13=>267107+11400}
      expect(disc).to receive(:advancedTocScanner).once.and_return scanner
    end

    it "should use the provided toc scanner to calculate the disc" do
      expect(scanner).to receive(:respond_to?).with(:dataTracks).at_least(:once).and_return true

      expect(scanner).to receive(:dataTracks).at_least(3).and_return([13])
      expect(scanner).to receive(:firstAudioTrack).at_least(:once).and_return(1)
      expect(scanner).to receive(:audiotracks).at_least(:once).and_return(12)
      (1..13).each do |number|
        expect(scanner).to receive(:getStartSector).with(number).at_least(:once).and_return @start[number]
      end

      expect(@musicbrainz.musicbrainzLookupPath).to eq(@musicbrainzLookupPath)
      expect(@musicbrainz.discid).to eq("I5l9cCSFccLKFEKS.7wqSZAorPU-")
    end
  end
end
