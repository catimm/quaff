require 'spec_helper'

RSpec.describe SparkPost::Request do
  describe '#request' do
    api_url = 'https://api.sparkpost.com/api/'

    let(:api_key) { '123' }
    let(:request) { SparkPost::Request.request }

    success_response = {
      results: {
        'total_rejected_recipients' => 0,
        'total_accepted_recipients' => 1,
        'id' => '123456789123456789'
      }
    }

    context 'when GET request was successful' do
      before do
        stub_request(:get, api_url).to_return(
          body: JSON.generate(success_response),
          status: 200)
      end
      it do
        expect(SparkPost::Request.request(api_url, '123', {}, 'GET'))
          .to eq(success_response[:results])
      end
    end

    context 'when PUT request was successful' do
      before do
        stub_request(:put, api_url).to_return(
          body: JSON.generate(success_response),
          status: 200)
      end
      it do
        expect(SparkPost::Request.request(api_url, '123', {}, 'PUT'))
          .to eq(success_response[:results])
      end
    end

    context 'when DELETE request was successful' do
      before do
        stub_request(:delete, api_url).to_return(
          body: JSON.generate(success_response),
          status: 200)
      end
      it do
        expect(SparkPost::Request.request(api_url, '123', {}, 'DELETE'))
          .to eq(success_response[:results])
      end
    end

    context 'when POST request was successful' do
      before do
        stub_request(:post, api_url).to_return(
          body: JSON.generate(success_response),
          status: 200)
      end
      it do
        expect(SparkPost::Request.request(api_url, '123', {}))
          .to eq(success_response[:results])
      end
    end

    context 'when request was not successful' do
      response = { errors: { message: 'end of world' } }
      before do
        stub_request(:post, api_url).to_return(
          body: JSON.generate(response),
          status: 500)
      end

      it do
        expect { SparkPost::Request.request(api_url, '123', {}) }
          .to raise_error(SparkPost::DeliveryException).with_message(
            /end of world/)
      end
    end

    describe 'json encoding' do
      api_url = 'https://api.sparkpost.com/api/'
      before do
        stub_request(:post, api_url).to_return(
          body: JSON.generate({}),
          status: 200)
      end

      it 'encodes hash to json' do
        allow(JSON).to receive(:generate).with(foo: 'bar')
        SparkPost::Request.request(api_url, '123', foo: 'bar')
      end

      it 'does not encode nil to json' do
        expect(JSON).to_not receive(:generate)
        SparkPost::Request.request(api_url, '123', nil)
      end
    end
  end
end
