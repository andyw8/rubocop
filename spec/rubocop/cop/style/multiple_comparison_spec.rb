# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Style::MultipleComparison, :config do
  it 'does not register an offense for comparing an lvar' do
    expect_no_offenses(<<~RUBY)
      a = "a"
      if a == "a"
        print a
      end
    RUBY
  end

  it 'registers an offense and corrects when `a` is compared twice' do
    expect_offense(<<~RUBY)
      a = "a"
      if a == "a" || a == "b"
         ^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
        print a
      end
    RUBY

    expect_correction(<<~RUBY)
      a = "a"
      if ["a", "b"].include?(a)
        print a
      end
    RUBY
  end

  it 'registers an offense and corrects when `a` is compared three times' do
    expect_offense(<<~RUBY)
      a = "a"
      if a == "a" || a == "b" || a == "c"
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
        print a
      end
    RUBY

    expect_correction(<<~RUBY)
      a = "a"
      if ["a", "b", "c"].include?(a)
        print a
      end
    RUBY
  end

  it 'registers an offense and corrects when `a` is compared three times on the right hand side' do
    expect_offense(<<~RUBY)
      a = "a"
      if "a" == a || "b" == a || "c" == a
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
        print a
      end
    RUBY

    expect_correction(<<~RUBY)
      a = "a"
      if ["a", "b", "c"].include?(a)
        print a
      end
    RUBY
  end

  it 'registers an offense and corrects when `a` is compared three times, once on the ' \
     'right hand side' do
    expect_offense(<<~RUBY)
      a = "a"
      if a == "a" || "b" == a || a == "c"
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
        print a
      end
    RUBY

    expect_correction(<<~RUBY)
      a = "a"
      if ["a", "b", "c"].include?(a)
        print a
      end
    RUBY
  end

  it 'registers an offense and corrects when multiple comparison is not part of a conditional' do
    expect_offense(<<~RUBY)
      def foo(x)
        x == 1 || x == 2 || x == 3
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
      end
    RUBY

    expect_correction(<<~RUBY)
      def foo(x)
        [1, 2, 3].include?(x)
      end
    RUBY
  end

  it 'registers an offense and corrects when `a` is compared twice in `if` and `elsif` conditions' do
    expect_offense(<<~RUBY)
      def foo(a)
        if a == 'foo' || a == 'bar'
           ^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
        elsif a == 'baz' || a == 'qux'
              ^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
        elsif a == 'quux'
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      def foo(a)
        if ['foo', 'bar'].include?(a)
        elsif ['baz', 'qux'].include?(a)
        elsif a == 'quux'
        end
      end
    RUBY
  end

  it 'registers an offense and corrects when expression with more comparisons precedes an expression with less comparisons' do
    expect_offense(<<~RUBY)
      a = 1
      a == 1 || a == 2 || a == 3
      ^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
      a == 1 || a == 2
      ^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
    RUBY

    expect_correction(<<~RUBY)
      a = 1
      [1, 2, 3].include?(a)
      [1, 2].include?(a)
    RUBY
  end

  it 'does not register an offense for comparing multiple literal strings' do
    expect_no_offenses(<<~RUBY)
      if "a" == "a" || "a" == "c"
        print "a"
      end
    RUBY
  end

  it 'does not register an offense for comparing multiple int literals' do
    expect_no_offenses(<<~RUBY)
      if 1 == 1 || 1 == 2
        print 1
      end
    RUBY
  end

  it 'does not register an offense for comparing lvars' do
    expect_no_offenses(<<~RUBY)
      a = "a"
      b = "b"
      if a == "a" || b == "b"
        print a
      end
    RUBY
  end

  it 'does not register an offense for comparing lvars when a string is on the lefthand side' do
    expect_no_offenses(<<~RUBY)
      a = "a"
      b = "b"
      if a == "a" || "b" == b
        print a
      end
    RUBY
  end

  it 'does not register an offense for a == b || b == a' do
    expect_no_offenses(<<~RUBY)
      a = "a"
      b = "b"
      if a == b || b == a
        print a
      end
    RUBY
  end

  it 'does not register an offense for a duplicated condition' do
    expect_no_offenses(<<~RUBY)
      a = "a"
      b = "b"
      if a == b || a == b
        print a
      end
    RUBY
  end

  it 'does not register an offense for Array#include?' do
    expect_no_offenses(<<~RUBY)
      a = "a"
      if ["a", "b", "c"].include? a
        print a
      end
    RUBY
  end

  context 'when `AllowMethodComparison: true`' do
    let(:cop_config) { { 'AllowMethodComparison' => true } }

    it 'does not register an offense when using multiple method calls' do
      expect_no_offenses(<<~RUBY)
        col = loc.column
        if col == before.column || col == after.column
          do_something
        end
      RUBY
    end

    it 'does not register an offense when using multiple safe navigation method calls' do
      expect_no_offenses(<<~RUBY)
        col = loc.column
        if col == before&.column || col == after&.column
          do_something
        end
      RUBY
    end

    it 'registers an offense and corrects when `var` is compared multiple times after a method call' do
      expect_offense(<<~RUBY)
        var = do_something
        var == foo || var == 'bar' || var == 'baz'
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
      RUBY

      expect_correction(<<~RUBY)
        var = do_something
        var == foo || ['bar', 'baz'].include?(var)
      RUBY
    end

    it 'registers an offense and corrects when comparing with hash access on rhs' do
      expect_offense(<<~RUBY)
        if a[:key] == 'a' || a[:key] == 'b'
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
          print a
        end
      RUBY

      expect_correction(<<~RUBY)
        if ['a', 'b'].include?(a[:key])
          print a
        end
      RUBY
    end

    it 'registers an offense and corrects when comparing with hash access on lhs' do
      expect_offense(<<~RUBY)
        if 'a' == a[:key] || 'b' == a[:key]
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
          print a
        end
      RUBY

      expect_correction(<<~RUBY)
        if ['a', 'b'].include?(a[:key])
          print a
        end
      RUBY
    end

    it 'registers an offense and corrects when comparing with safe navigation method call on rhs' do
      expect_offense(<<~RUBY)
        if a&.do_something == 'a' || a&.do_something == 'b'
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
          print a
        end
      RUBY

      expect_correction(<<~RUBY)
        if ['a', 'b'].include?(a&.do_something)
          print a
        end
      RUBY
    end

    it 'registers an offense and corrects when comparing with safe navigation method call on lhs' do
      expect_offense(<<~RUBY)
        if 'a' == a&.do_something || 'b' == a&.do_something
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
          print a
        end
      RUBY

      expect_correction(<<~RUBY)
        if ['a', 'b'].include?(a&.do_something)
          print a
        end
      RUBY
    end
  end

  it 'does not register an offense when comparing two sides of the disjunction is unrelated' do
    expect_no_offenses(<<~RUBY)
      def do_something(foo, bar)
        bar.do_something == bar || foo == :sym
      end
    RUBY
  end

  context 'when `AllowMethodComparison: false`' do
    let(:cop_config) { { 'AllowMethodComparison' => false } }

    it 'registers an offense and corrects when using multiple method calls' do
      expect_offense(<<~RUBY)
        col = loc.column
        if col == before.column || col == after.column
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
          do_something
        end
      RUBY

      expect_correction(<<~RUBY)
        col = loc.column
        if [before.column, after.column].include?(col)
          do_something
        end
      RUBY
    end

    it 'registers an offense and corrects when `var` is compared multiple times after a method call' do
      expect_offense(<<~RUBY)
        var = do_something
        var == foo || var == 'bar' || var == 'baz'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
      RUBY

      expect_correction(<<~RUBY)
        var = do_something
        [foo, 'bar', 'baz'].include?(var)
      RUBY
    end

    it 'does not register an offense when comparing with hash access on rhs' do
      expect_no_offenses(<<~RUBY)
        if a[:key] == 'a' || a[:key] == 'b'
          print a
        end
      RUBY
    end

    it 'does not register an offense when comparing with hash access on lhs' do
      expect_no_offenses(<<~RUBY)
        if 'a' == a[:key] || 'b' == a[:key]
          print a
        end
      RUBY
    end

    it 'does not register an offense when comparing with safe navigation method call on rhs' do
      expect_no_offenses(<<~RUBY)
        if a&.do_something == 'a' || a&.do_something == 'b'
          print a
        end
      RUBY
    end

    it 'does not register an offense when comparing with safe navigation method call on lhs' do
      expect_no_offenses(<<~RUBY)
        if 'a' == a&.do_something || 'b' == a&.do_something
          print a
        end
      RUBY
    end
  end

  context 'when `ComparisonsThreshold`: 2' do
    let(:cop_config) { { 'ComparisonsThreshold' => 2 } }

    it 'registers an offense and corrects when `a` is compared twice' do
      expect_offense(<<~RUBY)
        a = "a"
        foo if a == "a" || a == "b"
               ^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
      RUBY

      expect_correction(<<~RUBY)
        a = "a"
        foo if ["a", "b"].include?(a)
      RUBY
    end
  end

  context 'when `ComparisonsThreshold`: 3' do
    let(:cop_config) { { 'ComparisonsThreshold' => 3 } }

    it 'registers an offense and corrects when `a` is compared thrice' do
      expect_offense(<<~RUBY)
        a = "a"
        foo if a == "a" || a == "b" || a == "c"
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid comparing a variable with multiple items in a conditional, use `Array#include?` instead.
      RUBY

      expect_correction(<<~RUBY)
        a = "a"
        foo if ["a", "b", "c"].include?(a)
      RUBY
    end

    it 'does not register an offense when `a` is compared twice' do
      expect_no_offenses(<<~RUBY)
        a = "a"
        foo if a == "a" || a == "b"
      RUBY
    end

    it 'does not register an offense when `a` is compared twice in multiple expressions' do
      expect_no_offenses(<<~RUBY)
        a = "a"
        foo if a == "a" || a == "b"
        bar if a == "a" || a == "b"
      RUBY
    end

    it 'does not register an offense when `a` is compared twice in different contexts expressions' do
      expect_no_offenses(<<~RUBY)
        def foo(a)
          a == "a" || a == "b"
        end

        def bar(a)
          a == "a" || a == "b"
        end
      RUBY
    end
  end
end
