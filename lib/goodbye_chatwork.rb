require "goodbye_chatwork/version"
require 'csv'
require 'fileutils'
require 'open-uri'
require 'json'
require 'faraday'
require 'faraday-cookie_jar'

module GoodbyeChatwork
  class Client
    REQUEST_INTERVAL = 1
    CHAT_SIZE = 40

    def initialize(id, pw, org_key, opt = {})
      @verbose = opt[:verbose]
      @id = id
      @pw = pw
      @org_key = org_key || ''
      @opt = opt
      @interval = opt[:inverval] || REQUEST_INTERVAL
      @base_url = opt[:base_url] || 'https://www.chatwork.com'
      @token = nil
      @client = Faraday.new @base_url do |builder|
        builder.request :url_encoded
        builder.use :cookie_jar
        builder.adapter Faraday.default_adapter
      end
    end

    def login
      login_r = @client.post '/login.php', email: @id, password: @pw, orgkey:@org_key, autologin: 'on'
      if login_r.env.status == 302
	@client.url_prefix = URI.parse(login_r.env.response_headers[:location].match(/^https?(:\/\/[-_.!~*\'()a-zA-Z0-9;\:\@&=+\$,%#]+)/).to_s)
        @client.get login_r.env.response_headers[:location]
      end

      r = @client.get "/"
      self.wait
      self.info "login as #{@id} ..."
      @token = r.body.match(/var ACCESS_TOKEN *= *'(.+)'/).to_a[1]
      @myid = r.body.match(/var MYID *= *'(.+)'/).to_a[1]
      raise 'no token' unless @token
      self.init_load
      self
    end

    def init_load
      self.info "load initial data..."
      r = @client.get "/gateway.php?cmd=init_load&myid=#{@myid}&_v=1.80a&_av=5&_t=#{@token}&ln=ja&rid=0&type=&new=1"
      self.wait
      d = JSON.parse(r.body)['result']
      @contacts = d['contact_dat']
      @rooms = d['room_dat']
    end

    def old_chat room_id, first_chat_id = 0
      self.info "get old chat #{first_chat_id}- ..."
      begin
        res = @client.get do |req|
          req.url "#{@client.url_prefix.to_s}gateway.php?cmd=load_old_chat&myid=#{@myid}&_v=1.80a&_av=5&_t=#{@token}&ln=ja&room_id=#{room_id}&last_chat_id=0&first_chat_id=#{first_chat_id}&jump_to_chat_id=0&unread_num=0&file=1&desc=1"
          req.options.timeout = 5              # open/read timeout in seconds
          req.options.open_timeout = 1000      # connection open timeout in seconds
        end
      rescue Faraday::ConnectionFailed => e
        retry_count ||= 0
        retry_count += 1
        if retry_count < 5
          retry
        else
          raise e
        end
      end
      self.wait
      r = JSON.parse(res.body)
      r['result']['chat_list'].sort_by { |i| i['id'].to_i }.reverse
    end

    def account(aid)
      @contacts[aid.to_s]
    end

    def file_download(file_id, opt = {})
      info = self.file_info file_id
      if !info[:url] || !info[:filename]
        self.info "download error #{file_id}"
        return
      end

      d = open(info[:url]).read
      self.info "download #{info[:filename]} ..."
      fn = "#{file_id}_#{info[:filename]}".force_encoding('utf-8')
      out = fn
      if opt[:dir]
        unless File.exists?(opt[:dir])
          self.info "mkdir #{opt[:dir]}"
          FileUtils.mkdir_p opt[:dir]
        end
        out = File.join(opt[:dir], fn)
      end
      open(out, 'wb') { |f| f.write d }
    end

    def file_info(file_id)
      self.info "get file info #{file_id} ..."
      r = @client.get do |req|
        req.url "#{@client.url_prefix.to_s}gateway.php?cmd=download_file&bin=1&file_id=#{file_id}"
        req.options.timeout = 5            # open/read timeout in seconds
        req.options.open_timeout = 10      # connection open timeout in seconds
      end
      self.wait
      b = r.headers['Content-disposition'].match(/filename="=\?UTF-8\?B\?(.+)\?="/).to_a[1]
      { url: r.headers['Location'], filename: b.unpack('m')[0] }
    end

    def export_csv(room_id, out, opt = {})
      self.info "export logs #{room_id} ..."
      CSV.open(out, "wb") do |csv|
        fid = 0
        loop do
          r = self.old_chat(room_id, fid)
          r.each do |i|
            if opt[:include_file]
              fid = i['msg'].match(/\[download\:([^\]]+)\]/).to_a[1]
              if fid
                begin
                  file_download fid, dir: opt[:dir]
                rescue Exception => e
                  self.info "download error #{fid} #{e.to_s}"
                end
              end
            end
            ac = self.account(i['aid'])
            csv << [Time.at(i['tm']).iso8601,
              (ac ? ac['name'] : i['aid']), i['msg']]
          end
          break if r.size < CHAT_SIZE
          fid = r.last['id']
        end
      end
      self.info "create #{out}"
    end

    def room_list
      @rooms.to_a.sort_by { |i| i[0].to_i }.map do |i|
        name = i[1]['n']
        member_ids = i[1]['m'].keys
        c = i[1]['c']
        if !name && member_ids.size == 1 && member_ids.first == @myid
          [i[0], 'mychat', c]
        elsif name
          [i[0], name, c]
        elsif member_ids.size == 2 && member_ids.include?(@myid)
          ac = self.account(member_ids.find { |i| i != @myid }) || {}
          [i[0], ac['name'], c]
        else
          [i[0], '...', c]
        end
      end
    end

    def info(d)
      STDERR.puts([Time.now.iso8601, d].flatten.join(' ')) if @verbose
    end

    def wait
      sleep(@interval + rand)
    end
  end
end
