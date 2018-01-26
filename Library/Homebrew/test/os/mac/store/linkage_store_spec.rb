require "os/mac/store/linkage_store"
require "os/mac/database/helpers/linkage_database_types"

describe LinkageStore do
  include LinkageDatabaseTypes

  subject { LinkageStore.new("scala") }

  describe "#update!" do
    it "should be concrete" do
      expect { subject.update!(path_values: {}, hash_values: {}) }
        .to_not raise_error(NotImplementedError)
    end
  end

  describe "#fetch" do
    describe "HASH_LINKAGE_TYPES" do
      let(:type) { LinkageDatabaseTypes::HASH_LINKAGE_TYPES.sample }

      it "should fetch hash values for a HASH_LINKAGE_TYPE" do
        expect(subject)
          .to receive(:fetch_hash_values).with(type: type)

        subject.fetch(type: type)
      end
    end

    describe "GENERALIZED_TYPES" do
      let(:type) { LinkageDatabaseTypes::GENERALIZED_TYPES.sample }

      it "should fetch path values for a GENERALIZED_TYPE" do
        expect(subject)
          .to receive(:fetch_path_values).with(type: type)

        subject.fetch(type: type)
      end
    end

    it "should be concrete" do
      expect { subject.fetch(type: nil) }
        .to_not raise_error(NotImplementedError)
    end
  end

  describe "#flush_condition" do
    it "should be concrete" do
      expect { subject.flush_condition }
        .to_not raise_error(NotImplementedError)
    end

    it "should return `name = '<key>'`" do
      subject.stub(:key) { "scala" }
      expect(subject.flush_condition).to eq("name = 'scala'")
    end
  end

  describe "#flush_cache!" do
    it "should be concrete" do
      expect { subject.flush_cache! }
        .to_not raise_error(NotImplementedError)
    end

    it "should call flush condition" do
      subject.stub(:flush_condition) { "name = 'scala'" }

      expect(subject)
        .to receive(:flush_condition)

      subject.flush_cache!
    end
  end
end
