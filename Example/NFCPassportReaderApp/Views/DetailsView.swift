//
//  DetailsView.swift
//  NFCPassportReaderApp
//
//  Created by Andy Qua on 30/10/2019.
//  Copyright © 2019 Andy Qua. All rights reserved.
//

import SwiftUI
import NFCPassportReader

struct Item : Identifiable {
    var id = UUID()
    var title : String
    var value : String
    
    var textColor : Color {
        return value.hasPrefix("FAILED") ? Color.red : Color.black
    }
}


struct DetailsView : View {    
    private var passport: NFCPassportModel
    private var sectionNames = ["Chip information", "Verification information", "Document signing certificate", "Country signing certificate", "Datagroup Hashes"]
    private var sections = [[Item]]()

    init( passport : NFCPassportModel ) {
        self.passport = passport
        sections.append(getChipInfoSection(self.passport))
        sections.append(getVerificationDetailsSection(self.passport))
        sections.append(getCertificateSigningCertDetails(certItems:self.passport.documentSigningCertificate?.getItemsAsDict()))
        sections.append(getCertificateSigningCertDetails(certItems:self.passport.countrySigningCertificate?.getItemsAsDict()))
        sections.append(getDataGroupHashesSection(self.passport))
    }
    
    var body: some View {
        VStack {
            List {
                ForEach( 0 ..< self.sectionNames.count ) { i in
                    SectionGroup(sectionTitle: self.sectionNames[i], items: self.sections[i])
                }
            }
        }
    }
    
    func getChipInfoSection(_ passport: NFCPassportModel) -> [Item] {
        // Build Chip info section
        let chipInfo = [Item(title:"LDS Version", value: passport.LDSVersion),
                        Item(title:"Data groups present", value: passport.dataGroupsPresent.joined(separator: ", ")),
                        Item(title:"Data groups read", value: passport.dataGroupsAvailable.map { $0.getName()}.joined(separator: ", "))]

        return chipInfo
    }
    
    func getVerificationDetailsSection(_ passport: NFCPassportModel) -> [Item] {
        // Build Verification Info section
        var aa : String = "Not supported"
        if passport.activeAuthenticationSupported {
            aa = passport.activeAuthenticationPassed ? "SUCCESS\nSignature verified" : "FAILED\nCould not verify signature"
        }

        let verificationDetails : [Item] = [
            Item(title: "Access Control", value: "BAC"),
            Item(title: "Active Authentication", value: aa),
            Item(title: "Document Signing Certificate", value: passport.documentSigningCertificateVerified ? "SUCCESS\nSOD Signature verified" : "FAILED\nCouldn't verify SOD signature"),
            Item(title: "Country signing Certificate", value: passport.passportCorrectlySigned ? "SUCCESS\nmatched to country signing certificate" : "FAILED\nCouldn't build trust chain"),
            Item(title: "Data group hashes", value: passport.passportDataNotTampered ? "SUCCESS\nAll hashes match" : "FAILED\nCouldn't match hashes" )
        ]

        return verificationDetails
    }
    
    func getCertificateSigningCertDetails( certItems : [CertificateItem : String]? ) -> [Item] {
        let titles : [String] = ["Serial number", "Signature algorithm", "Public key algorithm", "Certificate fingerprint", "Issuer", "Subject", "Valid from", "Valid to"]

        var items = [Item]()
        if certItems?.count ?? 0  == 0 {
            items.append( Item(title:"Certificate details", value: "NOT FOUND" ) )
        } else {
            for title in titles {
                let ci = CertificateItem(rawValue:title)!
                items.append( Item(title:title, value: certItems?[ci] ?? "") )
            }
        }
        return items
    }

    func getDataGroupHashesSection(_ passport: NFCPassportModel) -> [Item] {
        var dgHashes = [Item]()
        for id in DataGroupId.allCases {
            if let hash = passport.dataGroupHashes[id] {
                dgHashes.append( Item(title:hash.id, value:hash.match ? "MATCHED" : "UNMATCHED"))
                dgHashes.append( Item(title:"SOD Hash", value: hash.sodHash))
                dgHashes.append( Item(title:"Computed Hash", value: hash.computedHash))
            }
        }
        return dgHashes
    }

}

struct SectionGroup : View {
    var sectionTitle : String
    var items : [Item]
    
    var body: some View {
        Section(header: Text(sectionTitle)) {
            ForEach(self.items) { item in
                VStack(alignment:.leading, spacing:0) {
                    Text(item.title)
                        .font(.headline)
                    Text(item.value)
                        .foregroundColor(item.textColor)
                        .lineLimit(nil)
                }
            }
        }
    }
}


struct DetailsView_Previews: PreviewProvider {

    static var previews: some View {
        let settings = SettingsStore()
        let passport = NFCPassportModel()
        return DetailsView(passport:passport)
            .environmentObject(settings)
            .environment( \.colorScheme, .light)
    }
}


