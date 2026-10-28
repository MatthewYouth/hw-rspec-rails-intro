require 'rails_helper'

RSpec.describe 'TMDb search and add flow', type: :request do
  def html
    Nokogiri::HTML(response.body)
  end

  it 'links the homepage to the search form and back' do
    get movies_path
    expect(html.at_css('a[href="/search"]')).to be_present
    get search_tmdb_path
    expect(response).to have_http_status(:ok)
    expect(html.at_css('form#tmdb_form')['method']).to eq('get')
    expect(html.at_css('form#tmdb_form')['action']).to eq(search_tmdb_path)
    expect(html.at_css('a[href="/movies"]')).to be_present
    expect(html.at_css('table#search_movies')).to be_nil
  end

  it 'searches without persisting results, then saves the selected movie and lists it' do
    stub_request(:get, 'https://api.themoviedb.org/3/search/movie').
      with(query: hash_including('query' => 'This Life + 10')).
      to_return(status: 200, body: Rails.root.join('spec/fixtures/tmdb_search.json').read)

    expect { get search_tmdb_path, params: { title: 'This Life + 10', language: 'all' } }.
      not_to change(Movie, :count)
    expect(response).to have_http_status(:ok)
    rows = html.css('#search_movies tbody tr')
    expect(rows.size).to eq(2)
    expect(rows.first.text).to include('This Life + 10', 'R', '2007-01-02')
    form = rows.first.at_css('form')
    expect(form['method']).to eq('post')
    attributes = form.css('input[name^="movie["]').to_h do |input|
      [input['name'][/^movie\[(.+)\]$/, 1], input['value']]
    end
    expect { post form['action'], params: { movie: attributes } }.to change(Movie, :count).by(1)
    follow_redirect!
    expect(response.body).to include('This Life + 10 was successfully added to RottenPotatoes.')
    get movies_path
    expect(html.at_css('table#movies').text).to include('This Life + 10')
  end

  it 'shows a warning and hides results when the title is missing' do
    get search_tmdb_path, params: { title: '' }
    expect(html.at_css('.alert-warning').text).to include('Please fill in all required fields!')
    expect(html.at_css('#search_movies')).to be_nil
    get search_tmdb_path
    expect(response.body).not_to include('Please fill in all required fields!')
  end

  it 'shows no results table when TMDb returns no matches' do
    allow(Movie).to receive(:find_in_tmdb).and_return([])
    get search_tmdb_path, params: { title: 'missing' }
    expect(html.at_css('.alert-warning').text).to include('No movies found with given parameters!')
    expect(html.at_css('#search_movies')).to be_nil
  end

  it 'escapes movie titles and descriptions in the results' do
    allow(Movie).to receive(:find_in_tmdb).and_return([
      Movie.new(title: '<script>alert(1)</script>', description: '<img src=x onerror=alert(1)>', rating: 'R')
    ])
    get search_tmdb_path, params: { title: 'test' }
    expect(html.css('#search_movies script, #search_movies img')).to be_empty
    expect(html.at_css('#search_movies').text).to include('<script>alert(1)</script>')
  end
end
