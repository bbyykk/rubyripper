#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/disc/calcFreedbID'

describe CalcFreedbID do

  let(:disc) {double{'Disc'}.as_null_object}
  let(:scanner) {double{'AdvancedTocScanner'}.as_null_object}
  let(:prefs) {double('Preferences').as_null_object}
  let(:deps) {double('Dependency').as_null_object}
  let(:exec) {double('Execute').as_null_object}

  before(:each) do
    @freedb = CalcFreedbID.new(disc, prefs, deps, exec)
    @freedbString = "7F087C0A 10 150 13359 36689 53647 68322 81247 87332 \
106882 122368 124230 2174"
    expect(prefs).to receive(:cdrom).at_least(:once).and_return('/dev/cdrom')
  end

  context "When a help program for creating a freedbstring exists" do
    
    before(:each) do
      expect(deps).to receive(:platform).twice.and_return('i686-linux')
    end

    it "should first try to use discid" do      
      expect(deps).to receive(:installed?).with('discid').and_return true
      expect(exec).to receive(:launch).with('discid /dev/cdrom').and_return [@freedbString]
      expect(@freedb.freedbString).to eq(@freedbString)
      expect(@freedb.discid).to eq("7F087C0A")
    end

    it "should then try to use cd-discid" do
      expect(deps).to receive(:installed?).with('discid').and_return false
      expect(deps).to receive(:installed?).with('cd-discid').and_return true
      expect(exec).to receive(:launch).with('cd-discid /dev/cdrom').and_return [@freedbString]
      expect(@freedb.freedbString).to eq(@freedbString)
      expect(@freedb.discid).to eq("7F087C0A")
    end
  end

  context "When the platform is DARWIN (a.k.a. OS X)" do
    it "should unmount the disc properly and mount it afterwards" do
      expect(deps).to receive(:platform).twice.and_return('i686-darwin')
      expect(deps).to receive(:installed?).with('discid').and_return true
      expect(exec).to receive(:launch).with('diskutil unmount /dev/cdrom')
      expect(exec).to receive(:launch).with('discid /dev/cdrom').and_return [@freedbString]
      expect(exec).to receive(:launch).with('diskutil mount /dev/cdrom')

      expect(@freedb.freedbString).to eq(@freedbString)
      expect(@freedb.discid).to eq("7F087C0A")
    end
  end

  context "When no help program exists, try to calculate it manually" do
    before(:each) do
      @start = {1=>0, 2=>13209, 3=>36539, 4=>53497, 5=>68172, 6=>81097,
7=>87182, 8=>106732, 9=>122218, 10=>124080}
      expect(prefs).to receive(:debug).and_return false
      expect(deps).to receive(:installed?).twice.and_return false
      expect(disc).to receive(:advancedTocScanner).once.and_return scanner
    end

    it "should use the provided toc scanner to calculate the disc" do
      expect(scanner).to receive(:tracks).at_least(:once).and_return(10)
      expect(scanner).to receive(:totalSectors).at_least(:once).and_return(162919)
      (1..10).each do |number|
        expect(scanner).to receive(:getStartSector).with(number).at_least(:once).and_return @start[number]
      end

      expect(@freedb.freedbString).to eq(@freedbString)
      expect(@freedb.discid).to eq("7F087C0A")
    end
  end
end
