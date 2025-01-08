#!/usr/bin/env ruby
# frozen_string_literal: true

require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/calendar_v3'

require 'yaml'
require 'json'
require 'csv'

module Cache
  def cache(filename, permitted_classes = [])
    raise if filename.nil?

    if @use_cache && File.exist?(filename)
      YAML.safe_load(File.read(filename),
                     permitted_classes: permitted_classes)
    else
      File.write(filename, YAML.dump(i = yield))
      i
    end
  end
end

module CalGen
  @oauth_file = 'oauth.yaml'
  @use_cache = true
  @langs = %w[ja en] # zh ru th ko zh-TW # 日本語以外は en と同じ様子
  CAL_CLASSES = [
    Time,
    Date,
    DateTime,
    Google::Apis::CalendarV3::Event,
    Google::Apis::CalendarV3::Event::Creator,
    Google::Apis::CalendarV3::Event::Organizer,
    Google::Apis::CalendarV3::EventDateTime
  ].freeze
  YAML_FILENAME = 'jp_holidays.yaml'

  class << self
    include Cache
    attr_reader :langs

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
      credentials = get_auth_code(authorizer, user_id, oob_uri) if credentials.nil? || credentials.expires_at < Time.now
      credentials
    end

    def get(cid)
      # https://developers.google.com/calendar/api/v3/reference/events/list
      loop.inject([nil, []]) do |i, _|
        token, r = i
        result = @service.list_events(cid, page_token: token)
        r += result.items
        n = result.next_page_token
        break r if token == n || n.nil?

        [n, r]
      end
    end

    def fetch
      db = load
      @langs.each do |lang|
        # cid = "japanese__#{lang}@holiday.calendar.google.com"
        cid = "#{lang}.japanese#holiday@group.v.calendar.google.com"
        cache("#{cid}-events.yaml", CAL_CLASSES) { get(cid) }.each do |i|
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

    def load(filename = YAML_FILENAME)
      db = if File.exist?(filename)
             YAML.safe_load(File.read(filename),
                            permitted_classes: [Date, Symbol])
           else
             {}
           end
      db.default_proc = proc do |hash, key|
        hash[key] = Hash.new { |h, k| h[k] = [] }
      end
      db
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

class << db
  def translate_map
    each_with_object({}) do |i, tdb|
      _, val = i
      next if val[:ja] == '銀行休業日'
      raise if tdb[val[:ja]] && tdb[val[:ja]] != val[:en]

      tdb[val[:ja]] = val[:en]
    end.sort.to_h
  end
end

File.write(CalGen::YAML_FILENAME, YAML.dump(db))
File.write('jp_holidays.json', JSON.pretty_generate(db))
File.write('jp_holidays.csv', CSV.dump(db, CalGen.langs))
File.write('jp_holidays_translate_map.yaml', YAML.dump(db.translate_map))
