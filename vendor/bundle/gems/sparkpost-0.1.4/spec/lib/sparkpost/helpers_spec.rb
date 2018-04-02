require 'spec_helper'

RSpec.describe SparkPost::Helpers do
  let(:helpers) { SparkPost::Helpers }

  describe '#copy_value' do
    context 'when source is empty' do
      let(:src_hash) { {} }
      let(:dst_hash) { { dkey: 'val' } }

      copied_hash = { dkey: 'val' }

      it 'does not copy values' do
        helpers.copy_value(src_hash, :skey, dst_hash, :dkey)
        expect(dst_hash).to eq(copied_hash)
      end
    end

    context 'when source is not empty' do
      let(:src_hash) { { skey: 'val' } }
      let(:dst_hash) { {} }

      copied_hash = { dkey: 'val' }

      it 'copies values' do
        helpers.copy_value(src_hash, :skey, dst_hash, :dkey)
        expect(dst_hash).to eq(copied_hash)
      end
    end
  end

  describe '#deep_merge' do
    context 'when source_hash and other_hash have different keys' do
      let(:source_hash) { { key1: 'val1', key2: 'val2' } }
      let(:other_hash) { { key3: 'val3', key4: 'val4' } }

      merged_hash = {
        key1: 'val1',
        key2: 'val2',
        key3: 'val3',
        key4: 'val4'
      }

      it 'merges source_hash and other_hash' do
        expect(helpers.deep_merge(source_hash, other_hash)).to eq(merged_hash)
      end
    end

    context 'when other_hash has nil value' do
      let(:source_hash) { { key1: 'val1', key2: 'val2' } }
      let(:other_hash) { { key1: nil } }

      merged_hash = {
        key1: 'val1',
        key2: 'val2'
      }

      it 'merges source_hash and other_hash' do
        expect(helpers.deep_merge(source_hash, other_hash)).to eq(merged_hash)
      end
    end

    context 'when source_hash has nil value' do
      let(:source_hash) { { key1: nil } }
      let(:other_hash) { { key1: 'val1', key2: 'val2' } }

      merged_hash = {
        key1: 'val1',
        key2: 'val2'
      }

      it 'merges source_hash and other_hash' do
        expect(helpers.deep_merge(source_hash, other_hash)).to eq(merged_hash)
      end
    end

    context 'when source_hash and other_hash have nested hash' do
      let(:source_hash) { { key1: { s1: 'sv1' } } }
      let(:other_hash) { { key1: { s2: 'sv2' }, key2: 'val2' } }

      merged_hash = {
        key1: { s1: 'sv1', s2: 'sv2' },
        key2: 'val2'
      }

      it 'merges source_hash and other_hash' do
        expect(helpers.deep_merge(source_hash, other_hash)).to eq(merged_hash)
      end
    end
  end
end
