# frozen_string_literal: true

RSpec.describe BoxOffice do
  it 'is defined' do
    expect(defined?(described_class)).to be_falsy
  end

  it 'is a module' do
    expect(described_class).to be_a(Module)
  end

  it 'successfully loads files from the support folder' do
    expect(TestHelper.test).to eq('Helper loaded successfully')
  end
end
