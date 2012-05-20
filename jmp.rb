# Copyright (C) 2012 Kyle Johnson <kyle@vacantminded.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#
# Shorten outgoing URLs with Bitly's j.mp URL shorener service.
#
# You must be registered with bit.ly/j.mp to use this script. URLs will be
# shortened if they are longer than the value confifugred below. The short
# URL is not displayed in the locally-printed message, but a message is shown
# above the message containing the URL indicating that it was shortened and
# what URL was sent to the server.
#
# TODO:
#   * Make the settings into WeeChat options.
#   * Make the cache a little better.
#   * Shorten timeout.
#   * Refactor.
#
# History:
#
#   2012-05-20:
#   version 0.3
#     * Re-license to MIT.
#     * Update comments and formatting.
#
#   2011-10-01:
#   version 0.2
#     * Changed output during startup to be more verbose.
#     * Added NOJMP keyword to disable shortening for a single message.
#     * Corrected version number.
#
#   2011-03-07:
#   version 0.1: first version
#     * basic functionality
#     * shortens URLs sent to server, persistent local cache
#     * prints shortened URL to current buffer
#  

require 'uri'
require 'net/http'

def weechat_init
  Weechat.register "jmp", "Kabaka", "0.2", "GPL3", "j.mp Link Shortener", "", ""

  Weechat.hook_command "jmp",
                       "Shorten URLs in the input bar (should be bound to a key).",
                       "", "", "", "jmp_cb", ""

  ###
  # Config settings below

  @jmp_login      = ""
  @jmp_api_key    = ""
  @min_url_length = 35

  # End config settings
  ####

  @cache = {}
  @cache_file_location = "#{Weechat.info_get("weechat_dir", "")}/jmpcache.ini"

  Weechat.print "", "j.mp: Loading URL cache from #{@cache_file_location}"

  cache_file = File.open(@cache_file_location, "r")

  count = 0

  cache_file.each_line do |line|
    unless line =~ /\A([^ ]+) ([^ ]+)\Z/
      Weechat.print "", "j.mp: WARNING: Malformed line in j.mp cache: #{line}"
      next
    end

    @cache[$1] = $2
    count += 1
  end

  cache_file.close

  Weechat.print "", "j.mp: Cache loaded with #{count} URLs."

  Weechat::WEECHAT_RC_OK
end


def jmp_cb(data, buffer, args)
  string = Weechat.buffer_get_string(buffer, "input")

  pos = 0

  string.split.each { |word|

    #if pos == 2
    #  word = word[1..word.length-1]
    #end

    if word =~ /\A(http|ftp)s?:\/\//

      if word.length >= @min_url_length

        # Found one! If it isn't in cache, feed it to j.mp.
        
        if @cache.has_key? word

          new_word = @cache[word]

        else

          url = URI.escape word, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")

          uri = URI("http://api.j.mp/v3/shorten?login=#{@jmp_login}&apiKey=#{@jmp_api_key}&format=txt&longUrl=#{url}")

          new_word = Net::HTTP.get(uri).chomp

          @cache[word] = new_word

          # This seems sub-optimal, but whatever.

          File.open(@cache_file_location, "a") do |f|
            f.puts "#{word} #{new_word}"
          end

        end
        # We're not building a new string from the array since we would lose
        # spacing. So just gsub the fixed URL into the original. Not really the
        # fastest thing to do, but it's not like we're sending thousands of
        # messages per second.

        string.gsub! word, new_word

        Weechat.print Weechat.current_buffer(), "[#{word} -> #{new_word}]"

      end

    end

    pos += 1
  }

  Weechat.buffer_set buffer, "input", string
end
