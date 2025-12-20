import * as admin from "firebase-admin";
import { sendPkwtExpirationNotification, testEmailNotification } from "./pkwt-notification";

// Initialize Firebase Admin
admin.initializeApp();

// Export functions
export { sendPkwtExpirationNotification, testEmailNotification };
