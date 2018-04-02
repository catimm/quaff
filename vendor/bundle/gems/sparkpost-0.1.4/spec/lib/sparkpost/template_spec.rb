require 'spec_helper'

RSpec.describe SparkPost::Template do
  describe '#initialize' do
    context 'when api key and host are passed'
    let(:template) do
      SparkPost::Template.new('123', 'http://sparkpost.com')
    end

    it { expect(template.instance_variables).to include(:@api_key) }
    it { expect(template.instance_variables).to include(:@api_host) }
    it { expect(template.instance_variable_get(:@api_key)).to eq('123') }
    it do
      expect(template.instance_variable_get(:@api_host))
        .to eq('http://sparkpost.com')
    end

    context 'when api key or host not passed' do
      it 'raises when api key and host not passed' do
        expect { SparkPost::Template.new }
          .to raise_error(ArgumentError)
      end
      it 'raises when host not passed' do
        expect { SparkPost::Template.new(123) }
          .to raise_error(ArgumentError)
      end
    end
  end

  describe '#endpoint' do
    let(:template) do
      SparkPost::Template.new('123456', 'https://api.sparkpost.com')
    end
    let(:url) { 'https://api.sparkpost.com/api/v1/templates' }

    it 'returns correct endpoint' do
      expect(template.endpoint).to eq(url)
    end

    it 'returns correct endpoint on subsequent calls' do
      template.endpoint

      expect(template.endpoint).to eq(url)
    end
  end

  describe '#create' do
    let(:template) do
      SparkPost::Template.new('123456', 'https://api.sparkpost.com')
    end
    let(:url) { 'https://api.sparkpost.com/api/v1/templates' }

    it 'calls request with correct data' do
      prepared_data = {
        content: {
          from: {
            email: 'me@me.com',
            name: 'Sparky'
          },
          subject: 'test subject',
          text: 'Hello Sparky',
          html: '<h1>Hello Sparky</h1>'
        },
        options: {
          transactional: true
        },
        id: 'sample-template',
        name: 'Sample Template'
      }

      allow(template).to receive(:request) do |req_url, req_api_key, req_data, req_verb|
        expect(req_verb).to eq('POST')
        expect(req_api_key).to eq('123456')
        expect(req_url).to eq(url)
        expect(req_data).to eq(prepared_data)
      end

      template.create(
        'sample-template',
        nil,
        'test subject',
        '<h1>Hello Sparky</h1>',
        text: 'Hello Sparky',
        is_transactional: true,
        name: 'Sample Template',
        from_name: 'Sparky',
        from_email: 'me@me.com'
      )
    end
  end

  describe '#update' do
    context 'draft update' do
      let(:template) do
        SparkPost::Template.new('123456', 'https://api.sparkpost.com')
      end
      let(:url) { 'https://api.sparkpost.com/api/v1/templates/sample-template' }

      it 'calls request with correct data' do
        prepared_data = {
          content: {
            from: 'me@me.com',
            subject: 'test subject',
            text: 'Hello Sparky',
            html: '<h1>Hello Sparky</h1>'
          },
          options: {
            transactional: true
          }
        }

        allow(template).to receive(:request) do |req_url, req_api_key, req_data, req_verb|
          expect(req_verb).to eq('PUT')
          expect(req_api_key).to eq('123456')
          expect(req_url).to eq(url)
          expect(req_data).to eq(prepared_data)
        end

        template.update(
          'sample-template',
          'me@me.com',
          'test subject',
          '<h1>Hello Sparky</h1>',
          text: 'Hello Sparky',
          is_transactional: true
        )
      end
    end

    context 'published update' do
      let(:template) do
        SparkPost::Template.new('123456', 'https://api.sparkpost.com')
      end
      let(:url) { 'https://api.sparkpost.com/api/v1/templates/sample-template?update_published=true' }

      it 'calls request with correct data' do
        prepared_data = {
          content: {
            from: 'me@me.com',
            subject: 'test subject',
            text: 'Hello Sparky',
            html: '<h1>Hello Sparky</h1>'
          },
          options: {
            transactional: true
          }
        }

        allow(template).to receive(:request) do |req_url, req_api_key, req_data, req_verb|
          expect(req_verb).to eq('PUT')
          expect(req_api_key).to eq('123456')
          expect(req_url).to eq(url)
          expect(req_data).to eq(prepared_data)
        end

        template.update(
          'sample-template',
          'me@me.com',
          'test subject',
          '<h1>Hello Sparky</h1>',
          text: 'Hello Sparky',
          is_transactional: true,
          update_published: true
        )
      end
    end
  end

  describe '#delete' do
    let(:template) do
      SparkPost::Template.new('123456', 'https://api.sparkpost.com')
    end
    let(:url) { 'https://api.sparkpost.com/api/v1/templates/sample-template' }

    it 'calls request with correct data' do
      allow(template).to receive(:request) do |req_url, req_api_key, _req_data, req_verb|
        expect(req_verb).to eq('DELETE')
        expect(req_api_key).to eq('123456')
        expect(req_url).to eq(url)
      end

      template.delete('sample-template')
    end
  end

  describe '#get' do
    let(:template) do
      SparkPost::Template.new('123456', 'https://api.sparkpost.com')
    end

    let(:template_id) { 'my-email-template' }

    context 'when retrieve published template' do
      let(:url) { "https://api.sparkpost.com/api/v1/templates/#{template_id}" }

      it 'calls request with correct data' do
        allow(template).to receive(:request) do |req_url, req_api_key, _req_data, req_verb|
          expect(req_verb).to eq('GET')
          expect(req_api_key).to eq('123456')
          expect(req_url).to eq(url)
        end

        template.get(template_id)
      end
    end

    context 'when retrieve draft template' do
      let(:url) { "https://api.sparkpost.com/api/v1/templates/#{template_id}?draft=true" }

      it 'calls request with correct data' do
        allow(template).to receive(:request) do |req_url, req_api_key, _req_data, req_verb|
          expect(req_verb).to eq('GET')
          expect(req_api_key).to eq('123456')
          expect(req_url).to eq(url)
        end

        template.get(template_id, true)
      end
    end
  end

  describe '#list' do
    let(:template) do
      SparkPost::Template.new('123456', 'https://api.sparkpost.com')
    end
    let(:url) { 'https://api.sparkpost.com/api/v1/templates' }

    it 'calls request with correct data' do
      allow(template).to receive(:request) do |req_url, req_api_key, _req_data, req_verb|
        expect(req_verb).to eq('GET')
        expect(req_api_key).to eq('123456')
        expect(req_url).to eq(url)
      end

      template.list
    end
  end

  describe '#preview' do
    let(:template) do
      SparkPost::Template.new('123456', 'https://api.sparkpost.com')
    end

    let(:template_id) { 'my-email-template' }

    context 'when retrieve published template' do
      let(:url) { "https://api.sparkpost.com/api/v1/templates/#{template_id}/preview" }

      it 'calls request with correct data' do
        allow(template).to receive(:request) do |req_url, req_api_key, req_data, req_verb|
          expect(req_verb).to eq('POST')
          expect(req_api_key).to eq('123456')
          expect(req_data).to eq(substitution_data: {})
          expect(req_url).to eq(url)
        end

        template.preview(template_id, {})
      end
    end

    context 'when retrieve draft template' do
      let(:url) { "https://api.sparkpost.com/api/v1/templates/#{template_id}/preview?draft=true" }

      it 'calls request with correct data' do
        allow(template).to receive(:request) do |req_url, req_api_key, req_data, req_verb|
          expect(req_verb).to eq('POST')
          expect(req_api_key).to eq('123456')
          expect(req_data).to eq(substitution_data: {})
          expect(req_url).to eq(url)
        end

        template.preview(template_id, {}, true)
      end
    end
  end
end
