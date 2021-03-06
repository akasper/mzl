require 'spec_helper'

describe 'Class' do
  let(:klass) do
    klass = Class.new
    klass.mzl.def :call_block do |*args, &block|
      block.call
    end

    klass.mzl.def :properties, persist: true do
      @properties ||= {}
    end

    klass.mzl.def :throw_the_instance do
      throw :the_instance, self
    end

    klass
  end

  describe '.mzl' do
    it 'responds with a Mzl::Thing' do
      Class.mzl.should be_a(Mzl::Thing)
    end

    specify 'subject is the calling class' do
      Class.mzl.subject.should == Class
      klass.mzl.subject.should == klass
      klass.mzl.new.mzl.subject.should == klass
    end

    specify 'with a block is the same as .mzl.new' do
      instance = klass.mzl do
        properties[:foo] = :bar
      end

      instance.instance_variable_get(:@properties)[:foo].should == :bar
    end

    specify 'is sane' do
      the_mzl = nil
      klazz = Class.new do
        the_mzl = mzl
      end

      klazz.mzl.should == the_mzl
    end

    describe '.new' do
      it 'returns an instance of of the subject class' do
        klass.mzl.new.should be_a(klass)
      end

      it 'passes parameters to the original .new method' do
        String.mzl.new("hello").should == "hello"
      end

      it 'sets self to the instance' do
        catch(:instance) do
          klass.mzl.new do
            throw :instance, self
          end.should be_a(klass)
        end
      end

      it 'instance_execs a block against the instance with mzl methods available' do
        instance_a = klass.mzl.new do
          properties[:foo] = :bar
        end

        instance_b = klass.mzl.new do
          properties[:foo] = :baz
        end

        [[instance_a, :bar], [instance_b, :baz]].each do |pair|
          instance, val = pair
          props = instance.instance_variable_get(:@properties)
          props.should be_a(Hash)
          props[:foo].should == val
        end
      end
    end

    describe '.override_new' do
      it 'replaces klass.new with mzl.new' do
        klass.mzl.new.should respond_to(:properties)
        klass.new.should_not respond_to(:properties)
        klass.mzl.override_new
        klass.new.should respond_to(:properties)
      end

      it 'can undo the override' do
        klass.mzl.override_new
        klass.new.should respond_to(:properties)
        klass.mzl.override_new(false)
        klass.new.should_not respond_to(:properties)
      end

      it 'preserves original .new behavior' do
        subklass = Class.new(klass)
        subklass.class_exec do
          attr_reader :foo

          def initialize
            @foo = :bar
          end

          mzl.override_new
        end

        subklass.new.foo.should == :bar
        subklass.mzl.new.foo.should == :bar
        subklass.new.should respond_to(:mzl)

        subklass.class_exec { mzl.override_new(false) }
        subklass.new.foo.should == :bar
        subklass.new.should_not respond_to(:mzl)
      end

      it 'does not pollute' do
        subklass = Class.new(klass)
        subklass.mzl.override_new

        klass.new.should_not respond_to(:mzl)
        subklass.new.should respond_to(:mzl)
      end
    end

    describe '.as' do
      it 'renames mzl to something else' do
        klass.class_exec do
          mzl_thing = mzl
          mzl.as :zl
        end

        klass.should_not respond_to(:mzl)
        klass.should respond_to(:zl)

        klass.class_exec do
          zl.as :mzl
        end

        klass.should_not respond_to(:zl)
        klass.should respond_to(:mzl)
      end
    end
  end
end