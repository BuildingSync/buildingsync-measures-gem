require_relative 'hvac_measure_test'

module HvacModifierTests
  def test_argument_contract
    assert_equal(self.class::ARGUMENT_NAMES, @measure.arguments(@model).map(&:name))
  end

  def test_rejects_blank_names
    values = valid_arguments.merge(self.class::SCOPE_ARGUMENT => ' , ')
    assert_rejected_without_changes(values, error: /required/)
  end

  def test_rejects_missing_name_before_changes
    values = valid_arguments
    values[self.class::SCOPE_ARGUMENT] += ', Missing Object'
    assert_rejected_without_changes(values, error: /not found.*Missing Object/)
  end
end