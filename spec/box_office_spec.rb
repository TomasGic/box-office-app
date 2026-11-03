RSpec.describe 'Test Suite Setup' do
  it 'successfully loads the application' do
    expect(defined?(BoxOffice)).to be_truthy
    expect(BoxOffice).to be_a(Module)
  end

  it 'successfully loads files from the support folder' do
    expect(TestHelper.test).to eq('Helper loaded successfully')
  end
end
