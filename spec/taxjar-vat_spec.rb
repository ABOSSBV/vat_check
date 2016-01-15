require 'spec_helper'

describe TaxJarVat do

  context 'lookup' do
    context 'an invalid vat' do
      it 'returns false for valid and exists' do
        response = TaxJarVat.lookup('XX123456789')
        expect(response[:valid]).to be_falsey
        expect(response[:exists]).to be_falsey
      end
    end

    context 'a valid vat', vcr: { cassette_name: 'requests/service_available_valid_vat', record: :none } do
      it 'returns tue for valid and the service response for exists' do
        response = TaxJarVat.lookup('GB333289454')
        service_response = response[:response]

        expect(response[:valid]).to be_truthy
        expect(response[:exists]).to be_truthy
        expect(service_response[:country_code]).to eq('GB')
        expect(service_response[:vat_number]).to eq('333289454')
        expect(service_response[:valid]).to eq(true)
        expect(service_response[:name]).to eq('BRITISH BROADCASTING CORPORATION')
        expect(service_response[:address].gsub("\n", " ")).to eq('FAO ALEX FITZPATRICK BBC GROUP VAT MANAGER THE LIGHT HOUSE (1ST FLOOR) MEDIA VILLAGE, 201 WOOD LANE LONDON W12 7TQ')
      end
    end

    context 'a valid but unkown vat', vcr: { cassette_name: 'requests/service_available_valid_but_unknown_vat', record: :none } do
      it 'returns true for valid and false for exists' do
        response = TaxJarVat.lookup('GB999999999')
        service_response = response[:response]

        expect(response[:valid]).to be_truthy
        expect(response[:exists]).to be_falsey
        expect(service_response[:country_code]).to eq('GB')
        expect(service_response[:vat_number]).to eq('999999999')
        expect(service_response[:valid]).to eq(false)
        expect(service_response[:name]).to eq('---')
        expect(service_response[:address]).to eq('---')
      end
    end

    context 'when service is unavailable and vat is valid', vcr: { cassette_name: 'requests/validate_ms_unavailable_error', record: :none } do
      it 'returns true for valid and service down message for exists' do
        response = TaxJarVat.lookup('GB333289454')
        service_response = response[:response]

        expect(response[:valid]).to be_truthy
        expect(response[:exists]).to be_falsey
        expect(service_response[:error]).to eq('Service unavailable')
      end
    end
  end

  context 'valid?' do
    it 'returns false for an invalid id' do
      expect(TaxJarVat.valid?('XX123456789')).to be_falsey
    end

    it 'returns true for a valid vat' do
      expect(TaxJarVat.valid?('GB333289454')).to be_truthy
    end
  end

  context 'exists?' do
    it 'returns false for an invalid vat' do
      expect(TaxJarVat.exists?('XX123456789')).to be_falsey
    end

    it 'returns true for a valid vat when the service is available', vcr: { cassette_name: 'requests/service_available_valid_vat', record: :none } do
      expect(TaxJarVat.exists?('GB333289454')).to be_truthy
    end

    it 'returns false if the vat is valid but the service is down', vcr: { cassette_name: 'requests/validate_ms_unavailable_error', record: :none } do
      expect(TaxJarVat.exists?('GB333289454')).to be_falsey
    end
  end
end