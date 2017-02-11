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

require 'rubyripper/metadata/musicbrainz/getMusicBrainzRelease'

describe GetMusicBrainzRelease do

  # helper function to return the query message in the stub
  def setQueryReply(query=nil)
    query ||= File.read('spec/metadata/musicbrainz/data/oneReleaseFound.xml')
    @releaseId = 'f15d1f3a-5bf4-3a96-95be-a801b3889dc6'
    expect(http).to receive(:get).with(@query_disc).and_return query
  end

  before(:all) do
    @disc = "discid/4vi.H1hC7BRP18_a.7D4r4NOYL8-?toc=1+17+215886+150+19849+33726+49423+65078+78067+113257+127326+139893+158225+169350+174474+180081+189063+196083+203467+214139"
    @query_disc = "/ws/2/#{@disc}&inc=artists+recordings+artist-credits"
  end

  let(:prefs) {double('Preferences').as_null_object}
  let(:http) {double('MusicBrainzWebService').as_null_object}
  let(:getMusicBrainz) {GetMusicBrainzRelease.new(http, prefs)}

  context "Given some existing inclusion parameters in the lookup path" do
    before(:each) do
      allow(prefs).to receive(:debug).and_return false
      expect(http).to receive(:path).at_least(:once).and_return "/ws/2/"
    end

    it "should not remove the existing parameters" do
      expect(prefs).to receive(:useEarliestDate).at_least(:once).and_return false
      expect(http).to receive(:get).with("/ws/2/#{@disc}&inc=something-else+artists+recordings+artist-credits").and_return '<ok/>'
      getMusicBrainz.queryDisc(@disc + '&inc=something-else')
    end

    it "should not duplicate any existing parameters" do
      expect(prefs).to receive(:useEarliestDate).at_least(:once).and_return false
      expect(http).to receive(:get).with("/ws/2/#{@disc}&inc=recordings+artists+artist-credits").and_return '<ok/>'
      getMusicBrainz.queryDisc(@disc + '&inc=recordings')
    end

    it "should add the release-groups parameter if useEarliestDate is set" do
      expect(prefs).to receive(:useEarliestDate).at_least(:once).and_return true
      expect(http).to receive(:get).with("/ws/2/#{@disc}&inc=recordings+artists+artist-credits+release-groups").and_return '<ok/>'
      getMusicBrainz.queryDisc(@disc + '&inc=recordings')
    end

    it "should not duplicate the release-groups parameter if useEarliestDate is set" do
      expect(prefs).to receive(:useEarliestDate).at_least(:once).and_return true
      expect(http).to receive(:get).with("/ws/2/#{@disc}&inc=recordings+release-groups+artists+artist-credits").and_return '<ok/>'
      getMusicBrainz.queryDisc(@disc + '&inc=recordings+release-groups')
    end
  end

  context "Given there is only an empty instance" do
    it "should not crash if there are no choices but the caller still chooses" do
      allow(prefs).to receive(:debug).and_return false
      getMusicBrainz.choose(0)
      expect(getMusicBrainz.status).to eq('noChoices')
      expect(getMusicBrainz.musicbrainzRelease).to eq(nil)
    end
  end

  context "After firing a query for a disc to the MusicBrainz web service" do

    before(:each) do
      allow(prefs).to receive(:debug).and_return false
      expect(http).to receive(:path).at_least(:once).and_return "/ws/2/"
      expect(prefs).to receive(:useEarliestDate).at_least(:once).and_return false
    end

    it "should handle the response in case no disc is reported" do
      setQueryReply(File.read('spec/metadata/musicbrainz/data/noReleasesFound.xml'))
      getMusicBrainz.queryDisc(@disc)

      expect(getMusicBrainz.status).to eq('noMatches')
      expect(getMusicBrainz.musicbrainzRelease).to eq(nil)
      expect(getMusicBrainz.choices).to eq(nil)
    end

    it "should handle the response in case 1 release is reported" do
      setQueryReply()
      getMusicBrainz.queryDisc(@disc)

      expect(getMusicBrainz.status).to eq('ok')
      expect(getMusicBrainz.musicbrainzRelease.attributes['id']).to eq(@releaseId)
      expect(getMusicBrainz.choices).to eq(nil)
    end

    it "should adhere to country preferences for multiple results if specified" do
      # Only rely on country preferences.
      allow(prefs).to receive(:preferMusicBrainzCountries).and_return 'AU'
      allow(prefs).to receive(:preferMusicBrainzDate).and_return 'no'
      setQueryReply(File.read('spec/metadata/musicbrainz/data/multipleReleasesFound.xml'))
      @releaseId = '0923a33a-45c4-3eed-aae8-8b50e1a545de'
      getMusicBrainz.queryDisc(@disc)

      expect(getMusicBrainz.status).to eq('ok')
      expect(getMusicBrainz.musicbrainzRelease.attributes['id']).to eq(@releaseId)
      expect(getMusicBrainz.choices.length).to eq(1)
    end

    it "should adhere to date preferences for multiple results if specified" do
      # Only rely on date preferences.
      allow(prefs).to receive(:preferMusicBrainzCountries).and_return ''
      allow(prefs).to receive(:preferMusicBrainzDate).and_return 'earlier'
      setQueryReply(File.read('spec/metadata/musicbrainz/data/multipleReleasesFound.xml'))
      @releaseId = '6bb3793b-f991-378e-9bff-0bd3117f2298'
      getMusicBrainz.queryDisc(@disc)

      expect(getMusicBrainz.status).to eq('ok')
      expect(getMusicBrainz.musicbrainzRelease.attributes['id']).to eq(@releaseId)
      expect(getMusicBrainz.choices.length).to eq(1)
    end

    it "should adhere to both preferences for multiple results if specified together" do
      # Only rely on date preferences.
      allow(prefs).to receive(:preferMusicBrainzCountries).and_return 'US'
      allow(prefs).to receive(:preferMusicBrainzDate).and_return 'later'
      setQueryReply(File.read('spec/metadata/musicbrainz/data/multipleReleasesFound.xml'))
      getMusicBrainz.queryDisc(@disc)

      expect(getMusicBrainz.status).to eq('ok')
      expect(getMusicBrainz.musicbrainzRelease.attributes['id']).to eq(@releaseId)
      expect(getMusicBrainz.choices.length).to eq(1)
    end

    context "when multiple records are reported and preferences cannot pick a 'best'" do
      before(:each) do
        allow(prefs).to receive(:preferMusicBrainzCountries).and_return ''
        allow(prefs).to receive(:preferMusicBrainzDate).and_return 'no'
        setQueryReply(File.read('spec/metadata/musicbrainz/data/multipleReleasesFound.xml'))
        getMusicBrainz.queryDisc(@disc)
      end

      it "should allow choosing the first disc" do
        expect(getMusicBrainz.status).to eq('multipleRecords')
        expect(getMusicBrainz.musicbrainzRelease).to eq(nil)
        expect(getMusicBrainz.choices.length).to eq(9)

        # choose the first disc
        @releaseId = '0923a33a-45c4-3eed-aae8-8b50e1a545de'
        getMusicBrainz.choose(0)
        expect(getMusicBrainz.status).to eq('ok')
        expect(getMusicBrainz.musicbrainzRelease.attributes['id']).to eq(@releaseId)
      end

      it "should allow choosing the second disc" do
        # choose the second disc
        @releaseId = '105975c7-0e63-3874-8ef7-261d6aebcb49'
        getMusicBrainz.choose(1)
        expect(getMusicBrainz.status).to eq('ok')
        expect(getMusicBrainz.musicbrainzRelease.attributes['id']).to eq(@releaseId)
      end

      it "should allow choosing an invalid choice without crashing" do
        # choose an unknown
        expect(getMusicBrainz.status).to eq('multipleRecords')
        getMusicBrainz.choose(9)
        expect(getMusicBrainz.status).to eq('choiceNotValid: 9')
        expect(getMusicBrainz.musicbrainzRelease).to eq(nil)
      end
    end

    context "when multiple records are reported for country preference and some records are missing the date or country element" do
      before(:each) do
        allow(prefs).to receive(:preferMusicBrainzCountries).and_return 'AU'
        allow(prefs).to receive(:preferMusicBrainzDate).and_return 'no'
        setQueryReply(File.read('spec/metadata/musicbrainz/data/multipleReleasesFound_invalidElements.xml'))
        getMusicBrainz.queryDisc(@disc)
        @releaseId = '0923a33a-45c4-3eed-aae8-8b50e1a545de'
      end

      it "should not crash if date element is not found" do
        expect(getMusicBrainz.status).to eq('ok')
        expect(getMusicBrainz.musicbrainzRelease.attributes['id']).to eq(@releaseId)
        expect(getMusicBrainz.choices.length).to eq(1)
      end

      it "should not crash if country element is not found" do
        expect(getMusicBrainz.status).to eq('ok')
        expect(getMusicBrainz.musicbrainzRelease.attributes['id']).to eq(@releaseId)
        expect(getMusicBrainz.choices.length).to eq(1)
      end
    end

    context "when multiple records are reported for date preference and some records are missing the date or country element" do
      before(:each) do
        allow(prefs).to receive(:preferMusicBrainzCountries).and_return ''
        allow(prefs).to receive(:preferMusicBrainzDate).and_return 'earlier'
        setQueryReply(File.read('spec/metadata/musicbrainz/data/multipleReleasesFound_invalidElements.xml'))
        getMusicBrainz.queryDisc(@disc)
        @releaseId = '6bb3793b-f991-378e-9bff-0bd3117f2298'
      end

      it "should not crash if date element is not found" do
        expect(getMusicBrainz.status).to eq('ok')
        expect(getMusicBrainz.musicbrainzRelease.attributes['id']).to eq(@releaseId)
        expect(getMusicBrainz.choices.length).to eq(1)
      end

      it "should not crash if country element is not found" do
        expect(getMusicBrainz.status).to eq('ok')
        expect(getMusicBrainz.musicbrainzRelease.attributes['id']).to eq(@releaseId)
        expect(getMusicBrainz.choices.length).to eq(1)
      end
    end
  end
end
