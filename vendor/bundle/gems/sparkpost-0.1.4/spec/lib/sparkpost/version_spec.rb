require 'spec_helper'

RSpec.describe 'Sparkpost' do
  it 'has a version' do
    expect(SparkPost::VERSION).to eq('0.1.4')
  end
end
