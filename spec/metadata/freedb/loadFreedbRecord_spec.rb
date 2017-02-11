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

require 'rubyripper/metadata/freedb/loadFreedbRecord'

describe LoadFreedbRecord do

  before(:all) do
    @dir = File.join(ENV['HOME'], '.cddb')
    @discid = '12345678'
    @freedb = 'A UTF-8 record that conforms to freedb standards'
    @nonUTF8 = "hello red \xE8".force_encoding("UTF-8")
    @result = ['/some/samplefile/12345678']
  end

  let(:file){double('fileAndDir').as_null_object}
  let(:load){LoadFreedbRecord.new(file)}

  context "When no local records are found" do
    it "should set the status and contents accordingly" do
      expect(file).to receive(:glob).with("#{@dir}/*/#{@discid}").and_return(Array.new)

      load.scan('12345678')
      expect(load.status).to eq('noRecords')
      expect(load.freedbRecord).to eq(nil)
    end
  end

  context "When one record is found" do
    it "should load the file and set the status to ok" do
      expect(file).to receive(:glob).with("#{@dir}/*/#{@discid}").and_return(@result)
      expect(file).to receive(:read).with(@result[0], 'r:UTF-8').and_return(@freedb)

      load.scan('12345678')
      expect(load.status).to eq('ok')
      expect(load.freedbRecord).to eq(@freedb)
    end
  end

  context "When two records or more are found" do
    it "should load the first file when 2 records are found" do
      result = ['/at/some/place/12345678', '/at/other/place/12345678']
      expect(file).to receive(:glob).with("#{@dir}/*/#{@discid}").and_return(result)
      expect(file).to receive(:read).with(result[0], 'r:UTF-8').and_return(@freedb)

      load.scan('12345678')
      expect(load.status).to eq('ok')
      expect(load.freedbRecord).to eq(@freedb)
    end
  end

  context "When the record is not encoded in UTF-8" do
    it "should first try to read the input as a ISO-8859-1 file" do
      expect(file).to receive(:glob).with("#{@dir}/*/#{@discid}").and_return(@result)
      expect(file).to receive(:read).with(@result[0], 'r:UTF-8').and_return(@nonUTF8)
      expect(file).to receive(:read).with(@result[0], 'r:ISO-8859-1').and_return(@freedb)

      load.scan('12345678')
      expect(load.status).to eq('ok')
      expect(load.freedbRecord).to eq(@freedb)
    end
    
    it "should then try to read the input as a GB18030 file" do
      expect(file).to receive(:glob).with("#{@dir}/*/#{@discid}").and_return(@result)
      expect(file).to receive(:read).with(@result[0], 'r:UTF-8').and_return(@nonUTF8)
      expect(file).to receive(:read).with(@result[0], 'r:ISO-8859-1').and_return(@nonUTF8)
      expect(file).to receive(:read).with(@result[0], 'r:GB18030').and_return(@freedb)

      load.scan('12345678')
      expect(load.status).to eq('ok')
      expect(load.freedbRecord).to eq(@freedb)
    end
  end

  context "When the conversion failed" do
    it "should set the status accordingly and return nothing" do
      expect(file).to receive(:glob).with("#{@dir}/*/#{@discid}").and_return(@result)
      expect(file).to receive(:read).with(@result[0], 'r:UTF-8').and_return(@nonUTF8)
      expect(file).to receive(:read).with(@result[0], 'r:GB18030').and_return(@nonUTF8)
      expect(file).to receive(:read).with(@result[0], 'r:ISO-8859-1').and_return(@nonUTF8)

      load.scan('12345678')
      expect(load.status).to eq('invalidEncoding')
      expect(load.freedbRecord).to eq(nil)
    end
  end
end
