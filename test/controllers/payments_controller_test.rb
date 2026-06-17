require "test_helper"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  test "index requires authentication" do
    get pagos_path

    assert_redirected_to new_session_path
  end

  test "index renders for an authenticated user" do
    sign_in_as(User.take)

    get pagos_path

    assert_response :success
  end

  # -------------------------------------------------------
  # PaymentsController#create tests
  # -------------------------------------------------------
  setup do
    @user = users(:one)
    @cancha = canchas(:one)
    @turno = Turno.create!(
      cancha: @cancha,
      start_time: Time.current.change(hour: 14, min: 0, sec: 0),
      reservation_name: "Marcela",
      status: :active,
      payment_status: :pending
    )
  end

  # Requires authentication
  test "create requires authentication" do
    post turno_payments_path(@turno), params: { payment: { amount: 5000, payment_type: "complete" } }

    assert_redirected_to new_session_path
  end

  # AC3: Creates a payment record
  test "create registers a payment (AC3)" do
    sign_in_as(@user)

    assert_difference "Payment.count", 1 do
      post turno_payments_path(@turno),
        params: { payment: { amount: 5000, payment_type: "complete" } },
        as: :turbo_stream
    end

    payment = Payment.last
    assert_equal @turno, payment.turno
    assert_equal 5000.to_d, payment.amount
    assert_equal @user, payment.registered_by
    assert payment.paid_at.present?
  end

  # AC4: payment_type=complete → turno becomes :paid
  test "create with payment_type complete marks turno as paid (AC4)" do
    sign_in_as(@user)

    post turno_payments_path(@turno),
      params: { payment: { amount: 5000, payment_type: "complete" } },
      as: :turbo_stream

    assert @turno.reload.paid?
  end

  # AC4: price set and cumulative >= price → auto marks as paid
  test "create auto-marks paid when cumulative equals price (AC4)" do
    sign_in_as(@user)
    @turno.update!(price: 12_000)

    post turno_payments_path(@turno),
      params: { payment: { amount: 12_000, payment_type: "partial" } },
      as: :turbo_stream

    assert @turno.reload.paid?
  end

  # AC5: payment_type=partial → turno becomes :partial
  test "create with payment_type partial marks turno as partial (AC5)" do
    sign_in_as(@user)

    post turno_payments_path(@turno),
      params: { payment: { amount: 3000, payment_type: "partial" } },
      as: :turbo_stream

    assert @turno.reload.partial?
  end

  # AC5: price set and cumulative < price → partial (STRICT MATH)
  test "create with price set and partial cumulative marks turno partial even if complete selected (STRICT MATH)" do
    sign_in_as(@user)
    @turno.update!(price: 12_000)

    post turno_payments_path(@turno),
      params: { payment: { amount: 6000, payment_type: "complete" } },
      as: :turbo_stream

    assert @turno.reload.partial?
  end

  # Security: Cannot register payment on a cancelled turno
  test "create is blocked when turno is cancelled" do
    sign_in_as(@user)
    @turno.update!(status: :cancelled)

    assert_no_difference "Payment.count" do
      post turno_payments_path(@turno),
        params: { payment: { amount: 1000, payment_type: "complete" } },
        as: :turbo_stream
    end

    assert_redirected_to root_path
  end

  # AC6: cumulative exceeds price → error, no payment created
  test "create prevents overpayment when price is set (AC6)" do
    sign_in_as(@user)
    @turno.update!(price: 10_000)

    assert_no_difference "Payment.count" do
      post turno_payments_path(@turno),
        params: { payment: { amount: 15_000, payment_type: "complete" } },
        as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert @turno.reload.pending?
  end

  # AC8: Cannot register payment on a paid turno (Pundit blocks it)
  test "create is blocked when turno is already paid (AC8)" do
    sign_in_as(@user)
    @turno.update!(payment_status: :paid)

    assert_no_difference "Payment.count" do
      post turno_payments_path(@turno),
        params: { payment: { amount: 1000, payment_type: "complete" } },
        as: :turbo_stream
    end

    assert_redirected_to root_path
  end

  # Authorization: turno from a different complejo
  test "create is rejected for turno outside user complejo" do
    sign_in_as(@user)
    other_complejo = Complejo.create!(name: "Otro Complejo")
    other_cancha = other_complejo.canchas.create!(name: "Cancha X", sport: :padel)
    other_turno = Turno.create!(
      cancha: other_cancha,
      start_time: Time.current.change(hour: 15, min: 0, sec: 0),
      reservation_name: "Otro"
    )

    assert_no_difference "Payment.count" do
      post turno_payments_path(other_turno),
        params: { payment: { amount: 1000, payment_type: "complete" } },
        as: :turbo_stream
    end

    assert_redirected_to calendario_path
  end

  # Turbo Stream response
  test "create responds with turbo stream (NFR-2)" do
    sign_in_as(@user)

    post turno_payments_path(@turno),
      params: { payment: { amount: 5000, payment_type: "complete" } },
      as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
  end

  # Payment accumulation
  test "create accumulates payments and auto-pays when total reaches price" do
    sign_in_as(@user)
    @turno.update!(price: 10_000, payment_status: :partial)
    @turno.payments.create!(amount: 4000, paid_at: Time.current, registered_by: @user)

    post turno_payments_path(@turno),
      params: { payment: { amount: 6000, payment_type: "partial" } },
      as: :turbo_stream

    assert @turno.reload.paid?
    assert_equal 2, @turno.payments.count
  end

  # HTML fallback
  test "create redirects on html request" do
    sign_in_as(@user)

    post turno_payments_path(@turno),
      params: { payment: { amount: 5000, payment_type: "complete" } }

    assert_redirected_to turno_path(@turno)
  end
end
