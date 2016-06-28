#--
# Copyright (c) 2011 SUSE LINUX Products GmbH
#
# Author: Duncan Mac-Vicar P. <dmacvicar@suse.de>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'bicho/cli/command'
require 'bicho/client'

module Bicho::CLI::Commands
  # Command to display bug information.
  class Show < ::Bicho::CLI::Command
    private

    # check for supportconfigs and download
    def download_if_supportconfig(bug, attachment)
      if (attachment.content_type == 'application/x-gzip' || attachment.content_type == 'application/x-bzip-compressed-tar') &&
         attachment.summary =~ /supportconfig/i
        filename = "bsc#{bug.id}-#{attachment.id}-#{attachment.props['file_name']}"
        t.say("Downloading to #{t.color(filename, :even_row)}")
        begin
          data = attachment.data
          File.open(filename, 'w') do |f|
            f.write data.read
          end
        rescue StandardError => e
          t.say("#{t.color('Error:', :error)} Download of #{filename} failed: #{e}")
          raise
        end
      end
    end

    # handle bug attachments
    # (show or download supportconfig)
    def handle_attachments(bug, download_supportconfigs)
      t.say("Bug #{t.color(bug.id.to_s, :headline)} has #{bug.attachments.size} attachments")
      bug.attachments.each do |attachment|
        if download_supportconfigs
          download_if_supportconfig(bug, attachment)
        else
          # no download, just show
          t.say(" #{attachment.id} (#{attachment.props['file_name']}:#{attachment.content_type}) #{attachment.summary}")
        end
      end
    end

    public

    options do
      opt :format, "Format string, eg. '%{id}:%{priority}:%{summary}'", type: :string
      opt :attachments, 'Show attachments'
      opt :supportconfig, 'Download supportconfig attachments (only if --attachments is given)'
    end

    def do(global_opts, opts, args)
      client = ::Bicho::Client.new(global_opts[:bugzilla])
      client.get_bugs(*args).each do |bug|
        if opts[:format]
          t.say(bug.format(opts[:format]))
        elsif opts[:attachments]
          handle_attachments(bug, opts[:supportconfig])
        else
          t.say("#{t.color(bug.id.to_s, :headline)} #{bug.summary}")
        end
      end
      0
    end
  end
end
