require 'spec_helper'

describe 'Object' do
  describe '#blank?' do
    it { expect(''.blank?).to be(true) }
    it { expect(nil.blank?).to be(true) }
    it { expect(true.blank?).to be(false) }
    it { expect({}.blank?).to be(true) }
    it { expect({}.blank?).to be(true) }
    it { expect([].blank?).to be(true) }
  end

  describe '#present?' do
    it { expect(''.present?).to be(false) }
    it { expect(nil.present?).to be(false) }
    it { expect(true.present?).to be(true) }
    it { expect({}.present?).to be(false) }
    it { expect({}.present?).to be(false) }
    it { expect([].present?).to be(false) }
  end
end
