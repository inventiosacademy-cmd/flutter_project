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
 * Scheduled function - berjalan setiap hari jam 08:00 WIB (01:00 UTC)
 * Sends per-user email notifications for employees with PKWT expiring soon
 */
export const sendPkwtExpirationNotification = onSchedule(
    {
        schedule: "0 1 * * *", // Setiap hari jam 01:00 UTC = 08:00 WIB
        timeZone: "Asia/Jakarta",
        region: "asia-southeast2", // Region Indonesia
    },
    async () => {
        console.log("🚀 Starting PKWT expiration check (per-user notifications)...");

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
            let totalUsersNotified = 0;

            // 3. For each user, check their employees and send individual email
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
                    const hariSebelumExpired = userSettings.hariSebelumExpired || [30, 14, 7, 3, 1];

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

                    const expiringEmployees: Array<Employee & { hariExpired: number }> = [];

                    // Check each employee for expiration
                    for (const empDoc of employeesSnapshot.docs) {
                        const emp = empDoc.data() as Employee;
                        const hariExpired = hitungHariMenujuExpired(emp.tglPkwtBerakhir);

                        // Include ALL employees with PKWT expiring within 30 days
                        if (hariExpired >= 0 && hariExpired <= 30) {
                            expiringEmployees.push({ ...emp, hariExpired });
                        }
                    }

                    if (expiringEmployees.length === 0) {
                        console.log(`✅ User ${userId}: No employees to notify today`);
                        continue;
                    }

                    // Sort by days remaining (most urgent first)
                    expiringEmployees.sort((a, b) => a.hariExpired - b.hariExpired);

                    console.log(`📋 User ${userId}: Found ${expiringEmployees.length} employees to notify`);

                    // Send email to this user
                    const transporter = createEmailTransporter({
                        emailPengirim,
                        passwordAplikasi,
                        emailPenerima,
                        hariSebelumExpired,
                    });

                    const emailHtml = createEmailTemplate(expiringEmployees);

                    const mailOptions = {
                        from: `"HR Dashboard" <${emailPengirim}>`,
                        to: emailPenerima,
                        subject: `⚠️ [HR Dashboard] ${expiringEmployees.length} Karyawan dengan PKWT Segera Berakhir`,
                        html: emailHtml,
                    };

                    await transporter.sendMail(mailOptions);

                    console.log(`✅ User ${userId}: Email sent successfully to ${emailPenerima}`);
                    totalEmailsSent++;
                    totalUsersNotified++;

                    // Log notification for this user
                    await db.collection("notification_logs").add({
                        sentAt: admin.firestore.FieldValue.serverTimestamp(),
                        userId: userId,
                        recipientEmail: emailPenerima,
                        employeeCount: expiringEmployees.length,
                        employees: expiringEmployees.map((e) => ({
                            nama: e.nama,
                            hariExpired: e.hariExpired,
                        })),
                        status: "success",
                    });

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

            console.log(`✅ Notification run completed: ${totalEmailsSent} emails sent to ${totalUsersNotified} users`);

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
 */
export const testEmailNotification = onRequest(
    {
        region: "asia-southeast2",
        cors: true, // Enable CORS untuk akses dari web/app
    },
    async (req, res) => {
        console.log("🧪 Testing email notification (per-user)...");

        const db = admin.firestore();

        try {
            // Get userId from query parameter (sent from Flutter app)
            const requestedUserId = req.query.userId as string || "";

            if (requestedUserId) {
                console.log(`📱 Testing for specific user: ${requestedUserId}`);
            }

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
                // Test for specific user (from Flutter app)
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
                // Fallback: Find first user with notification settings
                const usersSnapshot = await db.collection("users").get();

                for (const userDoc of usersSnapshot.docs) {
                    const userSettingsDoc = await db
                        .collection("users")
                        .doc(userDoc.id)
                        .collection("settings")
                        .doc("notifications")
                        .get();

                    if (userSettingsDoc.exists) {
                        const userSettings = userSettingsDoc.data()!;
                        emailPenerima = userSettings.emailPenerima || "";

                        if (emailPenerima) {
                            testUserId = userDoc.id;
                            break;
                        }
                    }
                }

                if (!testUserId) {
                    res.status(400).json({
                        success: false,
                        message: "No users found with email notification settings configured. Please set up in Pengaturan.",
                    });
                    return;
                }
            }

            console.log(`📧 Testing with user ${testUserId}, recipient: ${emailPenerima}`);

            // 3. Get expiring employees for this test user (within 30 days)
            const employeesSnapshot = await db
                .collection("users")
                .doc(testUserId!) // Use testUserId which is guaranteed to be not null here
                .collection("employees")
                .get();

            const allExpiringEmployees: Array<Employee & { hariExpired: number }> = [];

            for (const empDoc of employeesSnapshot.docs) {
                const emp = empDoc.data() as Employee;
                const hariExpired = hitungHariMenujuExpired(emp.tglPkwtBerakhir);

                if (hariExpired >= 0 && hariExpired <= 30) {
                    allExpiringEmployees.push({ ...emp, hariExpired });
                }
            }

            if (allExpiringEmployees.length === 0) {
                res.json({
                    success: true,
                    message: `No employees with PKWT expiring within 30 days for user ${testUserId}`,
                    userId: testUserId,
                });
                return;
            }

            // Sort and send
            allExpiringEmployees.sort((a, b) => a.hariExpired - b.hariExpired);

            const transporter = createEmailTransporter({
                emailPengirim,
                passwordAplikasi,
                emailPenerima,
                hariSebelumExpired: [30, 14, 7, 3, 1],
            });

            const emailHtml = createEmailTemplate(allExpiringEmployees);

            await transporter.sendMail({
                from: `"HR Dashboard" <${emailPengirim}>`,
                to: emailPenerima,
                subject: `🧪 [TEST] ${allExpiringEmployees.length} Karyawan dengan PKWT Segera Berakhir`,
                html: emailHtml,
            });

            res.json({
                success: true,
                message: `Test email sent to ${emailPenerima}`,
                userId: testUserId,
                employeeCount: allExpiringEmployees.length,
                employees: allExpiringEmployees.map((e) => ({
                    nama: e.nama,
                    hariExpired: e.hariExpired,
                })),
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
