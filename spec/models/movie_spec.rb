require 'rails_helper'

RSpec.describe Movie, type: :model do
  describe '.find_in_tmdb' do
    let(:endpoint) { 'https://api.themoviedb.org/3/search/movie' }
    let(:body) { Rails.root.join('spec/fixtures/tmdb_search.json').read }
    let(:terms) { { title: 'This Life + 10', release_year: '2007', language: 'all' } }
    let(:query) { { api_key: 'test-key', query: 'This Life + 10', year: '2007' } }

    before do
      stub_request(:get, endpoint).with(query: query).to_return(status: 200, body: body)
    end

    it 'calls Faraday with an encoded title, optional year, and API key' do
      described_class.find_in_tmdb(terms, 'test-key')
      expect(a_request(:get, endpoint).with(query: query)).to have_been_made.once
    end

    it 'returns unsaved Movie objects with mapped attributes and R ratings' do
      movies = nil
      expect { movies = described_class.find_in_tmdb(terms, 'test-key') }.not_to change(Movie, :count)
      expect(movies.map(&:title)).to eq(['This Life + 10', 'Another Life'])
      expect(movies).to all(be_a(Movie))
      expect(movies).to all(be_new_record)
      expect(movies.map(&:rating)).to eq(%w[R R])
      expect(movies.first.description).to eq('A reunion ten years later.')
      expect(movies.first.release_date.to_date).to eq(Date.new(2007, 1, 2))
      expect(movies.last.release_date).to be_nil
    end

    it 'omits an empty optional year and the all-languages parameter' do
      request = stub_request(:get, endpoint).with(query: { api_key: 'test-key', query: 'Life' }).
        to_return(status: 200, body: '{"results":[]}')
      expect(described_class.find_in_tmdb({ title: 'Life', release_year: '', language: 'all' }, 'test-key')).to eq([])
      expect(request).to have_been_requested.once
    end

    it 'filters English-only results by original language' do
      stub_request(:get, endpoint).with(query: query.merge(language: 'en')).
        to_return(status: 200, body: body)
      movies = described_class.find_in_tmdb(terms.merge(language: 'en'), 'test-key')
      expect(movies.map(&:title)).to eq(['This Life + 10'])
    end

    it 'reads the default API key from the environment' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('TMDB_API_KEY').and_return('test-key')
      expect(described_class.find_in_tmdb(terms).size).to eq(2)
    end


    it 'passes the complete encoded URL as a single Faraday argument' do
      url = "#{endpoint}?api_key=test-key&query=This+Life+%2B+10&year=2007"
      response = instance_double(Faraday::Response, status: 200, success?: true, body: body)
      expect(Faraday).to receive(:get).with(url).and_return(response)
      expect(described_class.find_in_tmdb(terms, 'test-key').map(&:title)).
        to eq(['This Life + 10', 'Another Life'])
    end

    it 'can replay recorded HTTP responses when no API key is configured' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('TMDB_API_KEY').and_return(nil)
      url = "#{endpoint}?api_key=&query=This+Life+%2B+10&year=2007"
      request = stub_request(:get, url).to_return(status: 200, body: body)
      expect(described_class.find_in_tmdb(terms).map(&:title)).
        to eq(['This Life + 10', 'Another Life'])
      expect(request).to have_been_requested.once
    end

    it 'does not contact TMDb for a blank title' do
      expect(Faraday).not_to receive(:get)
      expect(described_class.find_in_tmdb({ title: '  ' }, 'test-key')).to eq([])
    end

    it 'reports an invalid API key' do
      stub_request(:get, endpoint).with(query: query).to_return(status: 401, body: '{}')
      expect { described_class.find_in_tmdb(terms, 'test-key') }.
        to raise_error(Movie::TmdbError, /Invalid TMDb API key/)
    end

    [500, 429].each do |status|
      it "handles HTTP #{status}" do
        stub_request(:get, endpoint).with(query: query).to_return(status: status, body: '{}')
        expect { described_class.find_in_tmdb(terms, 'test-key') }.to raise_error(Movie::TmdbError, /unavailable/)
      end
    end

    it 'handles malformed JSON' do
      stub_request(:get, endpoint).with(query: query).to_return(status: 200, body: 'not JSON')
      expect { described_class.find_in_tmdb(terms, 'test-key') }.to raise_error(Movie::TmdbError)
    end

    it 'handles a network timeout' do
      stub_request(:get, endpoint).with(query: query).to_timeout
      expect { described_class.find_in_tmdb(terms, 'test-key') }.to raise_error(Movie::TmdbError)
    end

    it 'handles an unexpected response structure' do
      stub_request(:get, endpoint).with(query: query).to_return(status: 200, body: '{"results":null}')
      expect { described_class.find_in_tmdb(terms, 'test-key') }.to raise_error(Movie::TmdbError)
    end
  end
end
