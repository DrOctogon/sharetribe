require 'spec_helper'

describe Result do
  let(:success) { Result::Success.new(1) }
  let(:success_nil) { Result::Success.new(nil) }
  let(:error) { Result::Error.new("some message", {some_data: true}) }


  def expect_success(result, expected_data)
    expect(result).to be_a(Result::Success)
    expect(result[:data]).to be_eql(expected_data)
  end

  def expect_error(result, expected_error_msg, expected_error_data=nil)
    expect(result).to be_a(Result::Error)
    expect(result[:error_msg]).to be_eql(expected_error_msg)
    expect(result[:data]).to be_eql(expected_error_data)
  end

  describe Result::Success do

    describe "#and_then" do

      it "returns new Success result" do
        expect_success(success.and_then { |v| Result::Success.new(v + 1) }, 2)
      end

      it "returns new Error result" do
        expect_error(success.and_then { |v| Result::Error.new(:error, v - 1) }, :error, 0)
      end

      it "raises if Result is not returned" do
        expect { success.and_then { |v| v + 1 } }.to raise_error("Block must return Result")
      end
    end

    describe "#maybe" do

      it "returns Some(value)" do
        expect(success.maybe.or_else(0)).to eql(1)
      end

      it "returns None if result data is a non-value" do
        expect(success_nil.maybe.or_else(0)).to eql(0)
      end
    end
  end

  describe "#on_success" do
    before(:each) {
      @executed = false
    }

    it "executes on success" do
      success.on_success { |data|
        @executed = true
        expect(data).to eq 1
      }

      expect(@executed).to eq true
    end

    it "does not execute on error" do
      error.on_success { |data|
        @executed = true
      }
      expect(@executed).to eq false
    end

    it "allows chaining by returning self" do
      expect(success.on_success {}).to be_a Result::Success
      expect(error.on_success {}).to be_a Result::Error
    end
  end

  describe "#on_error" do
    before(:each) {
      @executed = false
    }

    it "executes on error" do
      error.on_error { |error_msg, data|
        @executed = true
        expect(error_msg).to eq "some message"
        expect(data).to eq({some_data: true})
      }

      expect(@executed).to eq true
    end

    it "does not execute on success" do
      success.on_error { |error_msg, data|
        @executed = true
      }
      expect(@executed).to eq false
    end

    it "allows chaining by returning self" do
      expect(success.on_error {}).to be_a Result::Success
      expect(error.on_error {}).to be_a Result::Error
    end
  end

  describe Result::Error do

    let(:error) { Result::Error.new(:error, 1) }

    describe "#and_then" do

      it "is a no-op" do
        expect_error(error.and_then { |v| Result::Success(v + 1) }, :error, 1)
      end
    end

    describe "#maybe" do

      it "returns None" do
        expect(error.maybe.or_else(0)).to eql(0)
      end
    end
  end
end
