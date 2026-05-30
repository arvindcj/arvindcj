# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

def wrangler_value(key)
  return nil unless File.exist?("wrangler.toml")

  File.read("wrangler.toml")[/^\s*#{Regexp.escape(key)}\s*=\s*"([^"]+)"/, 1]
end

project_name = ENV["CLOUDFLARE_PAGES_PROJECT"].to_s
project_name = wrangler_value("name").to_s if project_name.empty?
project_name = "arvindcj" if project_name.empty?

production_branch = ENV.fetch("CLOUDFLARE_PAGES_PRODUCTION_BRANCH", "main")
account_id = ENV["CLOUDFLARE_ACCOUNT_ID"]
api_token = ENV["CLOUDFLARE_API_TOKEN"]

if ENV["DRY_RUN"] == "1"
  puts %(Would ensure Cloudflare Pages project "#{project_name}" with production branch "#{production_branch}".)
  exit 0
end

abort "Missing CLOUDFLARE_ACCOUNT_ID." if account_id.to_s.empty?
abort "Missing CLOUDFLARE_API_TOKEN." if api_token.to_s.empty?

base_uri = URI("https://api.cloudflare.com/client/v4/accounts/#{account_id}/pages/projects")
project_uri = URI("#{base_uri}/#{URI.encode_www_form_component(project_name)}")

def cloudflare_request(uri, api_token, method: Net::HTTP::Get, body: nil)
  request = method.new(uri)
  request["Authorization"] = "Bearer #{api_token}"
  request["Content-Type"] = "application/json"
  request.body = JSON.generate(body) if body

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  parsed = JSON.parse(response.body)
rescue JSON::ParserError
  raise "Cloudflare API returned non-JSON response with HTTP #{response.code}."
else
  return parsed if response.is_a?(Net::HTTPSuccess) && parsed["success"] != false

  errors = Array(parsed["errors"])
  details = errors.map do |error|
    code = error["code"]
    message = error["message"]
    code ? "#{message} [code: #{code}]" : message
  end.join("; ")

  error = RuntimeError.new(details.empty? ? "Cloudflare API request failed with HTTP #{response.code}." : details)
  error.define_singleton_method(:status) { response.code.to_i }
  raise error
end

begin
  cloudflare_request(project_uri, api_token)
  puts %(Cloudflare Pages project "#{project_name}" already exists.)
rescue RuntimeError => error
  raise unless error.respond_to?(:status) && error.status == 404

  puts %(Creating Cloudflare Pages project "#{project_name}".)
  cloudflare_request(
    base_uri,
    api_token,
    method: Net::HTTP::Post,
    body: {
      name: project_name,
      production_branch: production_branch
    }
  )
  puts %(Created Cloudflare Pages project "#{project_name}".)
end
