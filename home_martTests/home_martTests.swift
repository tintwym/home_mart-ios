//
//  home_martTests.swift
//  home_martTests
//
//  Created by Tint Wai Yan Min on 29/3/26.
//

import Foundation
import Testing
@testable import home_mart

struct home_martTests {

    @Test @MainActor
    func updatePasswordRejectsMismatchedConfirmation() async {
        let ok = await AuthStore.shared.updatePassword(
            currentPassword: "current12",
            newPassword: "newpass00",
            passwordConfirmation: "newpass99"
        )
        #expect(ok == false)
        #expect(AuthStore.shared.lastError?.contains("match") == true)
    }

    @Test @MainActor
    func updatePasswordRejectsShortNewPassword() async {
        let ok = await AuthStore.shared.updatePassword(
            currentPassword: "current12",
            newPassword: "short",
            passwordConfirmation: "short"
        )
        #expect(ok == false)
        #expect(AuthStore.shared.lastError?.contains("8") == true)
    }

    @Test @MainActor
    func updatePasswordRejectsSameAsCurrent() async {
        let ok = await AuthStore.shared.updatePassword(
            currentPassword: "samepassword",
            newPassword: "samepassword",
            passwordConfirmation: "samepassword"
        )
        #expect(ok == false)
        #expect(AuthStore.shared.lastError?.contains("different") == true)
    }

    @Test @MainActor
    func updatePasswordRequiresSessionAfterValidationPasses() async {
        AuthStore.shared.logout()
        let ok = await AuthStore.shared.updatePassword(
            currentPassword: "oldpass00",
            newPassword: "newpass00",
            passwordConfirmation: "newpass00"
        )
        #expect(ok == false)
        #expect(AuthStore.shared.lastError?.contains("signed in") == true)
    }

    @Test
    func userPasswordURLUsesMapiPath() {
        let url = APIConfiguration.userPasswordURL
        #expect(url.path.contains("mapi/user/password"))
    }
}
