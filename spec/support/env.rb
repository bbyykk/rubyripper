#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2012 Bouke Woudstra (boukewoudstra@gmail.com)
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

$rr_version = 'test'
$rr_url = 'https://github.com/bleskodev/rubyripper'
$run_specs = true

# define a lightweight alternative for translations
module GetText
  def _(txt) ; txt ; end
  def GetText.bindtextdomain(domain) ; ; end
  def GetText._(txt) ; txt ; end
end

def _(txt) ; txt ; end
def bindtextdomain(domain) ; ; end
