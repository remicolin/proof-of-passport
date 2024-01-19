export type DataHash = [number, number[]];

export type PassportData = {
  mrz: string;
  signatureAlgorithm: string;
  pubKey: {modulus?: string, curveName?: string, publicKeyQ?: string};
  dataGroupHashes: DataHash[];
  eContent: number[];
  encryptedDigest: number[];
};
<<<<<<< HEAD
=======
// Mock data for PassportData
export const mockPassportData: PassportData = {
  mrz: 'YourMockMR<<ZYourMoc<<kMRZYourMockMRZYourMockMRZ',
  signatureAlgorithm: 'RSA',
  pubKey: {
    modulus: 'YourModulus',
    curveName: 'YourCurveName',
    publicKeyQ: 'YourPublicKeyQ',
  },
  dataGroupHashes: [
    // Populate with DataHash objects as per your requirement
  ],
  eContent: [0, 1, 2], // Example values
  encryptedDigest: [3, 4, 5], // Example values
};
>>>>>>> UI
