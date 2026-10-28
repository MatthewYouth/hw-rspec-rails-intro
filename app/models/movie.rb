class Movie < ApplicationRecord
  class TmdbError < StandardError; end

  def self.find_in_tmdb(search_terms, api_key = ENV['TMDB_API_KEY'])
    terms = search_terms.is_a?(String) ? { title: search_terms } : search_terms.to_h.symbolize_keys
    return [] if terms[:title].blank?

    query = { api_key: api_key.to_s, query: terms[:title] }
    query[:year] = terms[:release_year] if terms[:release_year].present?
    query[:language] = terms[:language] if terms[:language].present? && terms[:language] != 'all'
    url = "https://api.themoviedb.org/3/search/movie?#{URI.encode_www_form(query)}"
    response = Faraday.get(url) do |request|
      request.options.open_timeout = 5
      request.options.timeout = 10
    end
    if response.status == 401
      raise TmdbError, 'Invalid TMDb API key. Please check TMDB_API_KEY.'
    end
    raise TmdbError, 'TMDb is unavailable. Please try again later.' unless response.success?

    data = JSON.parse(response.body)
    unless data.is_a?(Hash) && data['results'].is_a?(Array) && data['results'].all? { |movie| movie.is_a?(Hash) }
      raise TmdbError, 'TMDb is unavailable. Please try again later.'
    end
    results = data['results']
    if terms[:language] == 'en'
      results = results.select { |movie| movie['original_language'] == 'en' }
    end
    results.map do |movie|
      new(title: movie['title'], description: movie['overview'],
        release_date: movie['release_date'].presence, rating: 'R')
    end
  rescue Faraday::Error, JSON::ParserError, KeyError
    raise TmdbError, 'TMDb is unavailable. Please try again later.'
  end

  def self.all_ratings
    %w[G PG PG-13 R]
  end

  def self.with_ratings(ratings, sort_by)
    if ratings.nil?
      all.order sort_by
    else
      where(rating: ratings.map(&:upcase)).order sort_by
    end
  end
end
