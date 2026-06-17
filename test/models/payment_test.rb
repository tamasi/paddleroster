require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @cancha = canchas(:one)
    @turno = Turno.create!(cancha: @cancha, start_time: Time.zone.now.change(hour: 14), reservation_name: "Turno A", status: :active)
    @user = users(:one)
  end

  test "valid with amount, paid_at and turno" do
    payment = Payment.new(turno: @turno, amount: 100.50, paid_at: Time.current)

    assert payment.valid?
  end

  test "invalid without amount" do
    payment = Payment.new(turno: @turno, paid_at: Time.current)

    assert_not payment.valid?
    assert_includes payment.errors[:amount], "no puede estar en blanco"
  end

  test "invalid with amount not greater than zero" do
    payment = Payment.new(turno: @turno, amount: 0, paid_at: Time.current)

    assert_not payment.valid?
    assert_includes payment.errors[:amount], "debe ser mayor que 0"
  end

  test "invalid without paid_at" do
    payment = Payment.new(turno: @turno, amount: 100)

    assert_not payment.valid?
    assert_includes payment.errors[:paid_at], "no puede estar en blanco"
  end

  test "registered_by is optional" do
    payment = Payment.new(turno: @turno, amount: 100, paid_at: Time.current)

    assert payment.valid?
    assert_nil payment.registered_by
  end

  test "belongs to registered_by user when present" do
    payment = Payment.create!(turno: @turno, amount: 100, paid_at: Time.current, registered_by: @user)

    assert_equal @user, payment.registered_by
  end

  test "turno has many payments" do
    payment = Payment.create!(turno: @turno, amount: 50, paid_at: Time.current)

    assert_includes @turno.payments, payment
  end
end
