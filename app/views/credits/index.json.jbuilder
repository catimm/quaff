json.array!(@credits) do |credit|
  json.extract! credit, :id, :total_credit, :transaction_credit, :transaction_type, :account_id
  json.url credit_url(credit, format: :json)
end
