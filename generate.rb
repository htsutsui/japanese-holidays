#!/usr/bin/env ruby
# frozen_string_literal: true

require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/calendar_v3'

require 'yaml'
require 'json'
require 'csv'

module CalGen
  @oauth_file = 'oauth.yaml'
  @use_cache = true
  @langs = %w[ja en] # zh ru th ko zh-TW # 日本語以外は en と同じ様子

  class << self
    attr_reader :langs

    def cache(filename)
      raise if filename.nil?

      if @use_cache && File.exist?(filename)
        YAML.load(File.read(filename))
      else
        File.write(filename, YAML.dump(i = yield))
        i
      end
    end

    def get_auth_code(authorizer, user_id, oob_uri)
      url = authorizer.get_authorization_url(base_url: oob_uri)
      puts "Open #{url} in your browser and enter the resulting code:"
      code = $stdin.gets
      authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: oob_uri
      )
    end

    def get_credentials(oauth_file = @oauth_file, user_id = 'default')
      oob_uri = 'urn:ietf:wg:oauth:2.0:oob'
      scope = [Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY]
      client_id = Google::Auth::ClientId.from_file('client_secret.json')
      token_store = Google::Auth::Stores::FileTokenStore.new(file: oauth_file)
      authorizer = Google::Auth::UserAuthorizer.new(
        client_id, scope, token_store
      )
      credentials = authorizer.get_credentials(user_id)
      credentials = get_auth_code(authorizer, user_id, oob_uri) if credentials.nil?
      credentials
    end

    def get(cid)
      # https://developers.google.com/calendar/api/v3/reference/events/list
      loop.each_with_object([nil, []]) do |_, i|
        token, r = i
        result = @service.list_events(cid, page_token: token)
        r += result.items
        break r if token == (n = result.next_page_token)

        [n, r]
      end
    end

    def fetch
      db = Hash.new { |hash, key| hash[key] = Hash.new { |h, k| h[k] = [] } }
      @langs.each do |lang|
        # cid = "japanese__#{lang}@holiday.calendar.google.com"
        cid = "#{lang}.japanese#holiday@group.v.calendar.google.com"
        cache("#{cid}-events.yaml") { get(cid) }.each do |i|
          raise if i.start.date != i.end.date - 1

          db[i.start.date][lang.to_sym] = i.summary
        end
      end
      db
    end

    def main
      @service = Google::Apis::CalendarV3::CalendarService.new
      @service.authorization = get_credentials
      fetch.sort.to_h
    end
  end
end

class CSV
  class << self
    def dump(data, langs)
      CSV.generate(write_headers: true,
                   headers: ['date'] + langs) do |fp|
        data.each do |date, val|
          fp << ([date] + langs.map { |i| val[i.to_sym] })
        end
      end
    end
  end
end

db = CalGen.main
File.write('jp_holidays.yaml', YAML.dump(db))
File.write('jp_holidays.json', JSON.pretty_generate(db))
File.write('jp_holidays.csv', CSV.dump(db, CalGen.langs))
