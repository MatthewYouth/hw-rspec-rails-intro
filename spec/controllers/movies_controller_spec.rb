require 'rails_helper'

RSpec.describe MoviesController, type: :controller do
  describe 'searching TMDb' do
    let(:fake_results) { [double('movie1'), double('movie2')] }
    let(:terms) { { title: 'hardware', release_year: '1990', language: 'all' } }

    it 'calls the model with the search form fields' do
      expect(Movie).to receive(:find_in_tmdb).with(terms).and_return(fake_results)
      get :search_tmdb, params: terms
    end

    it 'supports the introductory search_terms example' do
      expect(Movie).to receive(:find_in_tmdb).with('hardware').and_return(fake_results)
      get :search_tmdb, params: { search_terms: 'hardware' }
    end

    context 'after a valid search' do
      before do
        allow(Movie).to receive(:find_in_tmdb).and_return(fake_results)
        get :search_tmdb, params: terms
      end

      it 'selects the Search Results template' do
        expect(response).to render_template('search_tmdb')
      end

      it 'makes the results available to the template' do
        expect(assigns(:movies)).to eq(fake_results)
      end
    end

    it 'shows an empty form on the first visit without calling TMDb' do
      expect(Movie).not_to receive(:find_in_tmdb)
      get :search_tmdb
      expect(assigns(:movies)).to eq([])
      expect(flash[:alert]).to be_nil
    end

    it 'warns about a blank title without calling TMDb' do
      expect(Movie).not_to receive(:find_in_tmdb)
      get :search_tmdb, params: { title: '  ', language: 'all' }
      expect(flash[:alert]).to eq('Please fill in all required fields!')
      expect(assigns(:movies)).to eq([])
    end

    it 'warns when the search has no matches' do
      allow(Movie).to receive(:find_in_tmdb).and_return([])
      get :search_tmdb, params: terms
      expect(flash[:alert]).to eq('No movies found with given parameters!')
    end

    it 'displays a model service error as a warning' do
      allow(Movie).to receive(:find_in_tmdb).and_raise(Movie::TmdbError, 'TMDb is unavailable.')
      get :search_tmdb, params: terms
      expect(flash[:alert]).to eq('TMDb is unavailable.')
      expect(assigns(:movies)).to eq([])
    end
  end

  describe 'adding a TMDb movie' do
    let(:attributes) do
      { title: 'Hardware', rating: 'R', description: 'A science fiction film.', release_date: '1990-09-14' }
    end

    it 'saves the selected movie and redirects with a success message' do
      expect { post :add_movie, params: { movie: attributes } }.to change(Movie, :count).by(1)
      expect(Movie.last).to have_attributes(title: 'Hardware', rating: 'R', description: attributes[:description])
      expect(Movie.last.release_date.to_date).to eq(Date.new(1990, 9, 14))
      expect(response).to redirect_to(search_tmdb_path)
      expect(flash[:notice]).to eq('Hardware was successfully added to RottenPotatoes.')
    end

    it 'does not mass assign unpermitted attributes' do
      post :add_movie, params: { movie: attributes.merge(id: 12345) }
      expect(Movie.last.id).not_to eq(12345)
    end
  end
end
