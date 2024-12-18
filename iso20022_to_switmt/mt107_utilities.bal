// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerinax/financial.iso20022.payments_clearing_and_settlement as pacsIsoRecord;
import ballerinax/financial.swift.mt as swiftmt;

# Get MT107 message from Pacs003Document
# + document - The Pacs003 document.
# + return - The corresponding MT107 message.
isolated function getMT107InstructionPartyFromPacs003Document(
        pacsIsoRecord:Pacs003Document document
) returns swiftmt:MT50C?|swiftmt:MT50L? {
    pacsIsoRecord:BranchAndFinancialInstitutionIdentification8? instructingParty = document.FIToFICstmrDrctDbt.GrpHdr.InstgAgt;

    if instructingParty is () {
        return ();
    }

    if instructingParty.FinInstnId.BICFI is string {
        return <swiftmt:MT50C>{
            name: MT50C_NAME,
            IdnCd: {
                content: instructingParty.FinInstnId.BICFI.toString(),
                number: NUMBER1
            }
        };
    }
    if instructingParty.FinInstnId.Othr?.Id is string {
        return <swiftmt:MT50L>{
            name: MT50L_NAME,
            PrtyIdn: {
                content: instructingParty.FinInstnId.Othr?.Id.toString(),
                number: NUMBER1
            }
        };
    }

    return ();
}

# Extracts the creditor's information from a Pacs003Document.
# + document - The Pacs003 document.
# + return - The corresponding MT50A or MT50K record, or null if no matching data is found.
isolated function getMT107CreditorFromPacs003Document(
        pacsIsoRecord:Pacs003Document document
) returns swiftmt:MT50A?|swiftmt:MT50K? {
    pacsIsoRecord:PartyIdentification272 creditor = document.FIToFICstmrDrctDbt.DrctDbtTxInf[0].Cdtr;

    if creditor.Id?.OrgId?.AnyBIC is string {
        return <swiftmt:MT50A>{
            name: MT50A_NAME,
            IdnCd: {
                content: creditor.Id?.OrgId?.AnyBIC.toString(),
                number: NUMBER1
            }
        };
    }
    if creditor.Nm is string || creditor.PstlAdr?.AdrLine is string[] {
        return <swiftmt:MT50K>{
            name: MT50K_NAME,
            Acc: {
                content: (<pacsIsoRecord:GenericOrganisationIdentification3>getFirstElementFromArray(creditor.Id?.PrvtId?.Othr))?.Id.toString(),
                number: NUMBER1
            },
            Nm: getNamesArrayFromNameString(creditor.Nm.toString()),
            AdrsLine: getMtAddressLinesFromMxAddresses(<string[]>creditor.PstlAdr?.AdrLine)
        };
    }

    return ();
}

# Extracts the creditor's bank information from a Pacs003Document.
#
# + document - The Pacs003 document.
# + return - The corresponding MT52A, MT52C, or MT52D record, or null if no matching data is found.
isolated function getMT107CreditorsBankFromPacs003Document(
        pacsIsoRecord:Pacs003Document document
) returns swiftmt:MT52A?|swiftmt:MT52C?|swiftmt:MT52D? {
    pacsIsoRecord:BranchAndFinancialInstitutionIdentification8 creditorsBank = document.FIToFICstmrDrctDbt.DrctDbtTxInf[0].CdtrAgt;

    if creditorsBank.FinInstnId?.BICFI is string {
        return <swiftmt:MT52A>{
            name: MT52A_NAME,
            IdnCd: {
                content: creditorsBank.FinInstnId.BICFI.toString(),
                number: NUMBER1
            },
            PrtyIdnTyp: {
                content: creditorsBank.FinInstnId?.ClrSysMmbId?.ClrSysId?.Cd.toString(),
                number: NUMBER1
            },
            PrtyIdn: {
                content: creditorsBank.FinInstnId?.ClrSysMmbId?.MmbId.toString(),
                number: NUMBER1
            }
        };
    }
    if creditorsBank.FinInstnId?.ClrSysMmbId?.MmbId is string {
        return <swiftmt:MT52C>{
            name: MT52C_NAME,
            PrtyIdn: {
                content: creditorsBank.FinInstnId.ClrSysMmbId?.MmbId.toString(),
                number: NUMBER1
            }
        };
    }
    if creditorsBank.FinInstnId?.Nm is string {
        return <swiftmt:MT52D>{
            name: MT52D_NAME,
            PrtyIdn: {
                content: creditorsBank.FinInstnId?.Othr?.Id.toString(),
                number: NUMBER1
            },
            PrtyIdnTyp: {
                content: creditorsBank.FinInstnId?.Othr?.SchmeNm?.Cd.toString(),
                number: NUMBER1
            },
            Nm: getNamesArrayFromNameString(creditorsBank.FinInstnId.Nm.toString()),
            AdrsLine: getMtAddressLinesFromMxAddresses(<string[]>creditorsBank.FinInstnId.PstlAdr?.AdrLine)
        };
    }

    return ();
}

# Extracts the sender's correspondent information from a Pacs003Document.
#
# + document - The Pacs003 document.
# + return - The corresponding MT53A or MT53B record, or null if no matching data is found.
isolated function getMT107SendersCorrespondentFromPacs003Document(
        pacsIsoRecord:Pacs003Document document
) returns swiftmt:MT53A?|swiftmt:MT53B? {
    pacsIsoRecord:BranchAndFinancialInstitutionIdentification8? sendersCorrespondent =
        document.FIToFICstmrDrctDbt.GrpHdr.InstgAgt;

    if sendersCorrespondent is () {
        return ();
    }

    if sendersCorrespondent.FinInstnId?.BICFI is string {
        return <swiftmt:MT53A>{
            name: MT53A_NAME,
            IdnCd: {
                content: sendersCorrespondent.FinInstnId.BICFI.toString(),
                number: NUMBER1
            },
            PrtyIdnTyp: sendersCorrespondent.FinInstnId?.ClrSysMmbId?.ClrSysId?.Cd is string ? {
                    content: sendersCorrespondent.FinInstnId.ClrSysMmbId?.ClrSysId?.Cd.toString(),
                    number: NUMBER1
                } : (),
            PrtyIdn: sendersCorrespondent.FinInstnId?.ClrSysMmbId?.MmbId is string ? {
                    content: sendersCorrespondent.FinInstnId.ClrSysMmbId?.MmbId.toString(),
                    number: NUMBER1
                } : ()
        };
    }
    if sendersCorrespondent.FinInstnId?.Nm is string {
        return <swiftmt:MT53B>{
            name: MT53B_NAME,
            PrtyIdn: sendersCorrespondent.FinInstnId?.ClrSysMmbId?.MmbId is string ? {
                    content: sendersCorrespondent.FinInstnId.ClrSysMmbId?.MmbId.toString(),
                    number: NUMBER1
                } : (),
            PrtyIdnTyp: sendersCorrespondent.FinInstnId?.ClrSysMmbId?.ClrSysId?.Cd is string ? {
                    content: sendersCorrespondent.FinInstnId.ClrSysMmbId?.ClrSysId?.Cd.toString(),
                    number: NUMBER1
                } : (),
            Lctn: {
                content: sendersCorrespondent.FinInstnId.Nm.toString(),
                number: NUMBER1
            }
        };
    }

    return ();
}

