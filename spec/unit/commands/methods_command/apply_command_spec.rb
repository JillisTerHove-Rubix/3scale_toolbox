RSpec.describe ThreeScaleToolbox::Commands::MethodsCommand::Apply::ApplySubcommand do
  let(:arguments) do
    {
      service_ref: 'someservice', remote: 'https://destination_key@destination.example.com',
      method_ref: 'somemethod'
    }
  end
  let(:options) { {} }
  let(:service_class) { class_double(ThreeScaleToolbox::Entities::Service).as_stubbed_const }
  let(:service) { instance_double(ThreeScaleToolbox::Entities::Service) }
  let(:remote) { instance_double(ThreeScale::API::Client, 'remote') }
  let(:method_class) { class_double(ThreeScaleToolbox::Entities::Method).as_stubbed_const }
  let(:method) { instance_double(ThreeScaleToolbox::Entities::Method) }
  let(:hits_id) { 1 }
  let(:hits) { { 'id' => hits_id } }
  subject { described_class.new(options, arguments, nil) }

  context '#run' do
    context 'when --disabled and --enabled set' do
      let(:options) { { disabled: true, enabled: true } }
      it 'error raised' do
        expect { subject.run }.to raise_error(ThreeScaleToolbox::Error, /mutually exclusive/)
      end
    end

    context 'valid params' do
      before :example do
        expect(service_class).to receive(:find).and_return(service)
        expect(subject).to receive(:threescale_client).and_return(remote)
      end

      context 'when service not found' do
        let(:service) { nil }

        it 'error raised' do
          expect { subject.run }.to raise_error(ThreeScaleToolbox::Error,
                                                /Service someservice does not exist/)
        end
      end

      context 'when method not found' do
        let(:method_attrs) do
          {
            'friendly_name' => arguments[:method_ref],
            'system_name' => arguments[:method_ref]
          }
        end

        before :example do
          expect(service).to receive(:hits).and_return(hits)
          expect(method_class).to receive(:find).with(service: service,
                                                      parent_id: hits_id,
                                                      ref: arguments[:method_ref])
                                                .and_return(nil)
          expect(method).to receive(:id).and_return(1)
        end

        it 'method created' do
          expect(method_class).to receive(:create).with(service: service,
                                                        parent_id: hits_id,
                                                        attrs: method_attrs)
                                                  .and_return(method)
          expect { subject.run }.to output(/Applied method id: 1/).to_stdout
        end

        context 'when name in options' do
          let(:options) { { name: 'new name' } }
          let(:method_attrs) do
            {
              'friendly_name' => options[:name],
              'system_name' => arguments[:method_ref]
            }
          end

          it 'friendly_name overriden' do
            expect(method_class).to receive(:create).with(service: service,
                                                          parent_id: hits_id,
                                                          attrs: method_attrs)
                                                    .and_return(method)
            expect { subject.run }.to output(/Applied method id: 1/).to_stdout
          end
        end
      end

      context 'when method found' do
        before :example do
          expect(service).to receive(:hits).and_return(hits)
          expect(method_class).to receive(:find).with(service: service,
                                                      parent_id: hits_id,
                                                      ref: arguments[:method_ref])
                                                .and_return(method)
          expect(method).to receive(:id).and_return(1)
        end

        context 'with no options' do
          let(:options) { {} }

          it 'method not updated' do
            expect { subject.run }.to output(/Applied method id: 1/).to_stdout
          end
        end

        context 'with options' do
          let(:options) { { name: 'some name', description: 'some descr' } }
          let(:method_attrs) do
            {
              'friendly_name' => options[:name],
              'description' => options[:description]
            }
          end

          it 'method updated' do
            expect(method).to receive(:update).with(method_attrs)
            expect { subject.run }.to output(/Applied method id: 1/).to_stdout
          end
        end

        context 'with disable option' do
          let(:options) { { disabled: true } }

          it 'method disabled' do
            expect(method).to receive(:disable)
            expect { subject.run }.to output(/Applied method id: 1/).to_stdout
          end
        end

        context 'with enabled option' do
          let(:options) { { enabled: true } }

          it 'method disabled' do
            expect(method).to receive(:enable)
            expect { subject.run }.to output(/Applied method id: 1/).to_stdout
          end
        end
      end
    end
  end
end