# assuming that FactoryBot is correctly setup

RSpec.describe 'ApplicationController', type: :request do
  describe 'GET /index' do
    context 'when current_user count_hits is less than 10000' do
      it 'does not render an error message' do
        user = FactoryBot.create(:user)
        get '/index'
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when current_user count_hits is equal to or greater than 10000' do
      it 'renders an error message' do
        user = FactoryBot.create(:user)
        get '/index'
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('over quota')
      end
    end
  end
end