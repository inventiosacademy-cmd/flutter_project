import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

// Interface untuk Employee data
interface Employee {
    id: string;
    nama: string;
    email?: string;
    posisi: string;
    departemen: string;
    atasanLangsung: string;
    tglMasuk: string;
    tglPkwtBerakhir: string;
    pkwtKe: number;
}

// Interface untuk notification settings
interface NotificationSettings {
    emailPenerima: string;
    emailPengirim: string;
    passwordAplikasi: string;
    hariSebelumExpired: number[];
}

/**
 * Fungsi untuk menghitung hari menuju expired
 */
function hitungHariMenujuExpired(tglPkwtBerakhir: string): number {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const endDate = new Date(tglPkwtBerakhir);
    endDate.setHours(0, 0, 0, 0);

    const diffTime = endDate.getTime() - today.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    return diffDays;
}

/**
 * Membuat transporter untuk Gmail SMTP
 */
function createEmailTransporter(settings: NotificationSettings) {
    return nodemailer.createTransport({
        service: "gmail",
        auth: {
            user: settings.emailPengirim,
            pass: settings.passwordAplikasi,
        },
    });
}

/**
 * Membuat HTML template untuk email notifikasi
 */
function createEmailTemplate(employees: Array<Employee & { hariExpired: number }>): string {
    const rows = employees.map((emp) => `
    <tr>
      <td style="padding: 12px; border-bottom: 1px solid #e0e0e0;">${emp.nama}</td>
      <td style="padding: 12px; border-bottom: 1px solid #e0e0e0;">${emp.posisi}</td>
      <td style="padding: 12px; border-bottom: 1px solid #e0e0e0;">${emp.departemen}</td>
      <td style="padding: 12px; border-bottom: 1px solid #e0e0e0;">${emp.tglPkwtBerakhir}</td>
      <td style="padding: 12px; border-bottom: 1px solid #e0e0e0; text-align: center;">
        <span style="background: ${emp.hariExpired <= 7 ? '#ef4444' : emp.hariExpired <= 14 ? '#f59e0b' : '#3b82f6'}; 
                     color: white; padding: 4px 12px; border-radius: 20px; font-weight: bold;">
          ${emp.hariExpired} hari
        </span>
      </td>
      <td style="padding: 12px; border-bottom: 1px solid #e0e0e0;">PKWT ke-${emp.pkwtKe}</td>
    </tr>
  `).join("");

    return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5;">
      <div style="max-width: 800px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
        
        <!-- Header -->
        <div style="background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%); padding: 30px; text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 24px;">⚠️ Pengingat PKWT Segera Berakhir</h1>
          <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0;">HR Dashboard Notification System</p>
        </div>
        
        <!-- Content -->
        <div style="padding: 30px;">
          <p style="color: #374151; font-size: 16px; line-height: 1.6;">
            Berikut adalah daftar karyawan dengan kontrak PKWT yang akan segera berakhir dan membutuhkan evaluasi:
          </p>
          
          <!-- Table -->
          <div style="overflow-x: auto; margin: 20px 0;">
            <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
              <thead>
                <tr style="background: #f8fafc;">
                  <th style="padding: 12px; text-align: left; border-bottom: 2px solid #e0e0e0; color: #1e40af;">Nama</th>
                  <th style="padding: 12px; text-align: left; border-bottom: 2px solid #e0e0e0; color: #1e40af;">Posisi</th>
                  <th style="padding: 12px; text-align: left; border-bottom: 2px solid #e0e0e0; color: #1e40af;">Departemen</th>
                  <th style="padding: 12px; text-align: left; border-bottom: 2px solid #e0e0e0; color: #1e40af;">Tanggal Berakhir</th>
                  <th style="padding: 12px; text-align: center; border-bottom: 2px solid #e0e0e0; color: #1e40af;">Sisa Hari</th>
                  <th style="padding: 12px; text-align: left; border-bottom: 2px solid #e0e0e0; color: #1e40af;">Status PKWT</th>
                </tr>
              </thead>
              <tbody>
                ${rows}
              </tbody>
            </table>
          </div>
          
          <!-- Action Button -->
          <div style="text-align: center; margin: 30px 0;">
            <p style="color: #6b7280; font-size: 14px;">
              Segera lakukan evaluasi untuk karyawan-karyawan di atas.
            </p>
          </div>
          
        </div>
        
        <!-- Footer -->
        <div style="background: #f8fafc; padding: 20px; text-align: center; border-top: 1px solid #e0e0e0;">
          <p style="color: #6b7280; font-size: 12px; margin: 0;">
            Email ini dikirim otomatis oleh HR Dashboard System.<br>
            Tanggal: ${new Date().toLocaleDateString("id-ID", {
        weekday: "long",
        year: "numeric",
        month: "long",
        day: "numeric"
    })}
          </p>
        </div>
        
      </div>
    </body>
    </html>
  `;
}

/**
 * Helper function to check if an employee has been evaluated
 */
async function isEmployeeEvaluated(db: admin.firestore.Firestore, userId: string, employeeId: string): Promise<boolean> {
    const evaluationsSnapshot = await db
        .collection("users")
        .doc(userId)
        .collection("evaluasi")  // ← Changed from "evaluations" to "evaluasi"
        .where("employeeId", "==", employeeId)
        .get();

    console.log(`🔍 Checking evaluation status for employee ${employeeId}: Found ${evaluationsSnapshot.docs.length} evaluation(s)`);

    // Employee is considered evaluated if there's at least one evaluation
    // that is NOT in draft status (status: belumTTD or selesai)
    for (const evalDoc of evaluationsSnapshot.docs) {
        const evalData = evalDoc.data();
        const status = evalData.status || "";

        console.log(`  📋 Evaluation ID: ${evalDoc.id}, Status: "${status}"`);

        // If there's a completed evaluation (not draft), employee is evaluated
        if (status === "belumTTD" || status === "selesai") {
            console.log(`  ✅ Employee ${employeeId} is EVALUATED (status: ${status})`);
            return true;
        }
    }

    console.log(`  ❌ Employee ${employeeId} is NOT evaluated (no completed evaluations found)`);
    return false;
}

/**
 * Scheduled function - berjalan setiap hari jam 08:00 WIB (01:00 UTC)
 * Sends individual email notifications for each employee with PKWT expiring soon and not yet evaluated
 */
export const sendPkwtExpirationNotification = onSchedule(
    {
        schedule: "0 1 * * *", // Setiap hari jam 01:00 UTC = 08:00 WIB
        timeZone: "Asia/Jakarta",
        region: "asia-southeast2", // Region Indonesia
    },
    async () => {
        console.log("🚀 Starting PKWT expiration check (individual employee notifications)...");

        const db = admin.firestore();

        try {
            // 1. Get GLOBAL sender settings
            const globalSettingsDoc = await db.collection("app_settings").doc("notifications").get();

            if (!globalSettingsDoc.exists) {
                console.error("❌ Global email settings not found in app_settings/notifications");
                return;
            }

            const globalData = globalSettingsDoc.data()!;
            const emailPengirim = globalData.emailPengirim || "";
            const passwordAplikasi = globalData.passwordAplikasi || "";

            if (!emailPengirim || !passwordAplikasi) {
                console.error("❌ Sender email or password not configured in app_settings/notifications");
                return;
            }

            console.log(`📧 Using sender email: ${emailPengirim}`);

            // 2. Get all users
            const usersSnapshot = await db.collection("users").get();
            console.log(`👥 Found ${usersSnapshot.docs.length} users to check`);

            let totalEmailsSent = 0;
            let totalEmployeesNotified = 0;

            // 3. For each user, check their employees and send individual email per employee
            for (const userDoc of usersSnapshot.docs) {
                const userId = userDoc.id;

                try {
                    // Get user-specific notification settings
                    const userSettingsDoc = await db
                        .collection("users")
                        .doc(userId)
                        .collection("settings")
                        .doc("notifications")
                        .get();

                    if (!userSettingsDoc.exists) {
                        console.log(`⏭️  User ${userId}: No notification settings configured, skipping`);
                        continue;
                    }

                    const userSettings = userSettingsDoc.data()!;
                    const emailPenerima = userSettings.emailPenerima || "";

                    if (!emailPenerima) {
                        console.log(`⏭️  User ${userId}: No recipient email configured, skipping`);
                        continue;
                    }

                    // Get this user's employees
                    const employeesSnapshot = await db
                        .collection("users")
                        .doc(userId)
                        .collection("employees")
                        .get();

                    const unevaluatedExpiringEmployees: Array<Employee & { hariExpired: number }> = [];

                    // Check each employee for expiration AND evaluation status
                    for (const empDoc of employeesSnapshot.docs) {
                        const emp = empDoc.data() as Employee;
                        const hariExpired = hitungHariMenujuExpired(emp.tglPkwtBerakhir);

                        // Only include employees with PKWT expiring within 30 days
                        if (hariExpired >= 0 && hariExpired <= 30) {
                            // Check if employee has been evaluated
                            const hasBeenEvaluated = await isEmployeeEvaluated(db, userId, empDoc.id);

                            // Only add if NOT evaluated
                            if (!hasBeenEvaluated) {
                                unevaluatedExpiringEmployees.push({
                                    ...emp,
                                    id: empDoc.id,
                                    hariExpired
                                });
                            }
                        }
                    }

                    if (unevaluatedExpiringEmployees.length === 0) {
                        console.log(`✅ User ${userId}: No unevaluated employees to notify`);
                        continue;
                    }

                    // Sort by days remaining (most urgent first)
                    unevaluatedExpiringEmployees.sort((a, b) => a.hariExpired - b.hariExpired);

                    console.log(`📋 User ${userId}: Found ${unevaluatedExpiringEmployees.length} unevaluated employees to notify`);

                    // Create email transporter
                    const transporter = createEmailTransporter({
                        emailPengirim,
                        passwordAplikasi,
                        emailPenerima,
                        hariSebelumExpired: [30, 14, 7, 3, 1],
                    });

                    // Send ONE EMAIL PER EMPLOYEE
                    for (const employee of unevaluatedExpiringEmployees) {
                        try {
                            // Create email template for single employee
                            const emailHtml = createEmailTemplate([employee]);

                            const mailOptions = {
                                from: `"HR Dashboard" <${emailPengirim}>`,
                                to: emailPenerima,
                                subject: `⚠️ [HR Dashboard] PKWT ${employee.nama} Segera Berakhir (${employee.hariExpired} Hari)`,
                                html: emailHtml,
                            };

                            await transporter.sendMail(mailOptions);

                            console.log(`✅ User ${userId}: Email sent for employee ${employee.nama} (${employee.hariExpired} days) to ${emailPenerima}`);
                            totalEmailsSent++;

                            // Log notification for this employee
                            await db.collection("notification_logs").add({
                                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                                userId: userId,
                                recipientEmail: emailPenerima,
                                employeeId: employee.id,
                                employeeName: employee.nama,
                                hariExpired: employee.hariExpired,
                                status: "success",
                            });

                        } catch (emailError) {
                            console.error(`❌ Error sending email for employee ${employee.nama}:`, emailError);

                            // Log error for this specific employee
                            await db.collection("notification_logs").add({
                                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                                userId: userId,
                                employeeId: employee.id,
                                employeeName: employee.nama,
                                status: "error",
                                error: String(emailError),
                            });
                        }
                    }

                    totalEmployeesNotified += unevaluatedExpiringEmployees.length;

                } catch (userError) {
                    console.error(`❌ Error processing user ${userId}:`, userError);

                    // Log error for this user
                    await db.collection("notification_logs").add({
                        sentAt: admin.firestore.FieldValue.serverTimestamp(),
                        userId: userId,
                        status: "error",
                        error: String(userError),
                    });
                }
            }

            console.log(`✅ Notification run completed: ${totalEmailsSent} emails sent for ${totalEmployeesNotified} unevaluated employees`);

        } catch (error) {
            console.error("❌ Critical error in notification system:", error);

            // Log critical error
            await db.collection("notification_logs").add({
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                status: "critical_error",
                error: String(error),
            });
        }
    }
);

/**
 * HTTP function untuk testing (bisa dipanggil manual)
 * Tests email notification for a specific user (from query param) or first user with settings
 * Sends individual emails for each unevaluated employee
 */
export const testEmailNotification = onRequest(
    {
        region: "asia-southeast2",
        cors: true, // Enable CORS untuk akses dari web/app
    },
    async (req, res) => {
        // SECURITY: Only allow POST requests
        if (req.method !== "POST") {
            res.status(405).send("Method Not Allowed");
            return;
        }

        // SECURITY: Verify Authentication Token
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            res.status(403).json({ error: "Unauthorized: Missing or invalid token" });
            return;
        }

        const idToken = authHeader.split("Bearer ")[1];
        let decodedToken;

        try {
            decodedToken = await admin.auth().verifyIdToken(idToken);
            console.log(`✅ Authenticated request from user: ${decodedToken.uid}`);
        } catch (error) {
            console.error("❌ Authentication failed:", error);
            res.status(403).json({ error: "Unauthorized: Invalid token" });
            return;
        }

        console.log("🧪 Testing email notification (secure mode)...");

        const db = admin.firestore();

        try {
            // Get userId from BODY (secure POST), not query param
            const requestedUserId = req.body.userId as string || decodedToken.uid;

            if (requestedUserId) {
                console.log(`📱 Testing for specific user: ${requestedUserId}`);
            }

            // ... (rest of the logic remains the same, just ensure it uses requestedUserId)

            // 1. Get GLOBAL sender settings
            const globalSettingsDoc = await db.collection("app_settings").doc("notifications").get();

            if (!globalSettingsDoc.exists) {
                res.status(400).json({
                    success: false,
                    message: "Global email settings not found. Please configure in app_settings/notifications",
                });
                return;
            }

            const globalData = globalSettingsDoc.data()!;
            const emailPengirim = globalData.emailPengirim || "";
            const passwordAplikasi = globalData.passwordAplikasi || "";

            if (!emailPengirim || !passwordAplikasi) {
                res.status(400).json({
                    success: false,
                    message: "Sender email or password not configured in app_settings/notifications",
                });
                return;
            }

            // 2. Determine which user to test
            let testUserId: string | null = null;
            let emailPenerima = "";

            if (requestedUserId) {
                // Check if requesting user matches token user (or is admin) - Optional enforcement
                if (requestedUserId !== decodedToken.uid) {
                    console.warn(`⚠️ User ${decodedToken.uid} requested test for different user ${requestedUserId}`);
                    // For now we allow it for testing, but in strict production you might want to block this
                }

                // Test for specific user
                const userSettingsDoc = await db
                    .collection("users")
                    .doc(requestedUserId)
                    .collection("settings")
                    .doc("notifications")
                    .get();

                if (userSettingsDoc.exists) {
                    const userSettings = userSettingsDoc.data()!;
                    emailPenerima = userSettings.emailPenerima || "";

                    if (emailPenerima) {
                        testUserId = requestedUserId;
                    } else {
                        res.status(400).json({
                            success: false,
                            message: `User ${requestedUserId} has no recipient email configured. Please set up in Pengaturan.`,
                        });
                        return;
                    }
                } else {
                    res.status(400).json({
                        success: false,
                        message: `User ${requestedUserId} has no notification settings. Please set up in Pengaturan.`,
                    });
                    return;
                }
            } else {
                // Fallback: Use the authenticated user
                testUserId = decodedToken.uid;

                // Get settings for auth user
                const userSettingsDoc = await db
                    .collection("users")
                    .doc(testUserId)
                    .collection("settings")
                    .doc("notifications")
                    .get();

                if (userSettingsDoc.exists) {
                    const userSettings = userSettingsDoc.data()!;
                    emailPenerima = userSettings.emailPenerima || "";
                }

                if (!emailPenerima) {
                    res.status(400).json({
                        success: false,
                        message: `User ${testUserId} has no recipient email configured. Please set up in Pengaturan.`,
                    });
                    return;
                }
            }

            console.log(`📧 Testing with user ${testUserId}, recipient: ${emailPenerima}`);

            // 3. Get expiring UNEVALUATED employees for this test user (within 30 days)
            const employeesSnapshot = await db
                .collection("users")
                .doc(testUserId!)
                .collection("employees")
                .get();

            const unevaluatedExpiringEmployees: Array<Employee & { hariExpired: number }> = [];

            for (const empDoc of employeesSnapshot.docs) {
                const emp = empDoc.data() as Employee;
                const hariExpired = hitungHariMenujuExpired(emp.tglPkwtBerakhir);

                if (hariExpired >= 0 && hariExpired <= 30) {
                    // Check if employee has been evaluated
                    const hasBeenEvaluated = await isEmployeeEvaluated(db, testUserId!, empDoc.id);

                    // Only add if NOT evaluated
                    if (!hasBeenEvaluated) {
                        unevaluatedExpiringEmployees.push({
                            ...emp,
                            id: empDoc.id,
                            hariExpired
                        });
                    }
                }
            }

            if (unevaluatedExpiringEmployees.length === 0) {
                res.json({
                    success: true,
                    message: `No unevaluated employees with PKWT expiring within 30 days for user ${testUserId}`,
                    userId: testUserId,
                });
                return;
            }

            // Sort by most urgent first
            unevaluatedExpiringEmployees.sort((a, b) => a.hariExpired - b.hariExpired);

            const transporter = createEmailTransporter({
                emailPengirim,
                passwordAplikasi,
                emailPenerima,
                hariSebelumExpired: [30, 14, 7, 3, 1],
            });

            let emailsSent = 0;
            const sentEmployees: Array<{ nama: string; hariExpired: number }> = [];

            // Send ONE EMAIL PER EMPLOYEE
            for (const employee of unevaluatedExpiringEmployees) {
                try {
                    const emailHtml = createEmailTemplate([employee]);

                    await transporter.sendMail({
                        from: `"HR Dashboard" <${emailPengirim}>`,
                        to: emailPenerima,
                        subject: `🧪 [TEST] PKWT ${employee.nama} Segera Berakhir (${employee.hariExpired} Hari)`,
                        html: emailHtml,
                    });

                    emailsSent++;
                    sentEmployees.push({
                        nama: employee.nama,
                        hariExpired: employee.hariExpired
                    });

                    console.log(`✅ Test email sent for employee ${employee.nama}`);
                } catch (emailError) {
                    console.error(`❌ Error sending email for employee ${employee.nama}:`, emailError);
                }
            }

            res.json({
                success: true,
                message: `Test emails sent: ${emailsSent} emails for ${emailsSent} unevaluated employees`,
                userId: testUserId,
                emailsSent: emailsSent,
                totalUnevaluatedEmployees: unevaluatedExpiringEmployees.length,
                employees: sentEmployees,
            });

        } catch (error) {
            console.error("Error:", error);
            res.status(500).json({
                success: false,
                error: String(error),
            });
        }
    }
);
