import SwiftUI

struct CheckoutView: View {
    @State private var promoCode: String = ""
    @State private var address: String = ""
    @State private var paymentMethod: PaymentMethod = .applePay

    private let items: [CheckoutLineItem] = [
        .init(title: "Sample item", subtitle: "Home Mart", price: "$49.00"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionTitle("Items")

                VStack(spacing: 12) {
                    ForEach(items) { item in
                        HStack(alignment: .top, spacing: 12) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "bag.fill")
                                        .foregroundStyle(.secondary)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(item.price)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }

                sectionTitle("Delivery")

                TextField("Address", text: $address, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )

                sectionTitle("Payment")

                Picker("Payment method", selection: $paymentMethod) {
                    ForEach(PaymentMethod.allCases) { m in
                        Text(m.title).tag(m)
                    }
                }
                .pickerStyle(.segmented)

                sectionTitle("Promo code")

                TextField("Code", text: $promoCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )

                Divider().opacity(0.4)

                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text("$49.00")
                        .font(.headline.weight(.semibold))
                }

                Button {
                    // TODO: payment flow
                } label: {
                    Text("Place order")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.black, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(16)
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CheckoutLineItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let price: String
}

private enum PaymentMethod: String, CaseIterable, Identifiable {
    case applePay
    case card

    var id: String { rawValue }
    var title: String {
        switch self {
        case .applePay: return "Apple Pay"
        case .card: return "Card"
        }
    }
}

