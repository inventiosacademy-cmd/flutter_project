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

// Default settings (bisa diubah di Firestore)
const DEFAULT_SETTINGS: NotificationSettings = {
    emailPenerima: "",
    emailPengirim: "",
    passwordAplikasi: "",
    hariSebelumExpired: [30, 14, 7, 3, 1], // Kirim notifikasi H-30, H-14, H-7, H-3, H-1
};

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
 */
export const sendPkwtExpirationNotification = onSchedule(
    {
        schedule: "0 1 * * *", // Setiap hari jam 01:00 UTC = 08:00 WIB
        timeZone: "Asia/Jakarta",
        region: "asia-southeast2", // Region Indonesia
    },
    async () => {
        console.log("🚀 Starting PKWT expiration check...");

        const db = admin.firestore();

        try {
            // 1. Get notification settings from Firestore
            const settingsDoc = await db.collection("settings").doc("notifications").get();
            const settings: NotificationSettings = settingsDoc.exists
                ? { ...DEFAULT_SETTINGS, ...settingsDoc.data() as Partial<NotificationSettings> }
                : DEFAULT_SETTINGS;

            if (!settings.emailPengirim || !settings.passwordAplikasi || !settings.emailPenerima) {
                console.error("❌ Email settings not configured. Please set up in Firestore.");
                return;
            }

            // 2. Get all users
            const usersSnapshot = await db.collection("users").get();

            const allExpiringEmployees: Array<Employee & { hariExpired: number; userId: string }> = [];

            // 3. For each user, check employees with expiring PKWT
            for (const userDoc of usersSnapshot.docs) {
                const employeesSnapshot = await db
                    .collection("users")
                    .doc(userDoc.id)
                    .collection("employees")
                    .get();

                for (const empDoc of employeesSnapshot.docs) {
                    const emp = empDoc.data() as Employee;
                    const hariExpired = hitungHariMenujuExpired(emp.tglPkwtBerakhir);

                    // Check if this is a notification day (H-30, H-14, H-7, H-3, H-1)
                    if (settings.hariSebelumExpired.includes(hariExpired)) {
                        allExpiringEmployees.push({
                            ...emp,
                            hariExpired,
                            userId: userDoc.id,
                        });
                    }
                }
            }

            console.log(`📋 Found ${allExpiringEmployees.length} employees with PKWT expiring on notification days`);

            if (allExpiringEmployees.length === 0) {
                console.log("✅ No notifications to send today");
                return;
            }

            // 4. Sort by days remaining (most urgent first)
            allExpiringEmployees.sort((a, b) => a.hariExpired - b.hariExpired);

            // 5. Send email
            const transporter = createEmailTransporter(settings);
            const emailHtml = createEmailTemplate(allExpiringEmployees);

            const mailOptions = {
                from: `"HR Dashboard" <${settings.emailPengirim}>`,
                to: settings.emailPenerima,
                subject: `⚠️ [HR Dashboard] ${allExpiringEmployees.length} Karyawan dengan PKWT Segera Berakhir`,
                html: emailHtml,
            };

            await transporter.sendMail(mailOptions);

            console.log(`✅ Email sent successfully to ${settings.emailPenerima}`);

            // 6. Log notification history
            await db.collection("notification_logs").add({
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                recipientEmail: settings.emailPenerima,
                employeeCount: allExpiringEmployees.length,
                employees: allExpiringEmployees.map((e) => ({
                    nama: e.nama,
                    hariExpired: e.hariExpired,
                })),
                status: "success",
            });

        } catch (error) {
            console.error("❌ Error sending notification:", error);

            // Log error
            await db.collection("notification_logs").add({
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                status: "error",
                error: String(error),
            });
        }
    }
);

/**
 * HTTP function untuk testing (bisa dipanggil manual)
 */
export const testEmailNotification = onRequest(
    {
        region: "asia-southeast2",
        cors: true, // Enable CORS untuk akses dari web/app
    },
    async (req, res) => {
        console.log("🧪 Testing email notification...");

        const db = admin.firestore();

        try {
            // Get settings
            const settingsDoc = await db.collection("settings").doc("notifications").get();
            const settings: NotificationSettings = settingsDoc.exists
                ? { ...DEFAULT_SETTINGS, ...settingsDoc.data() as Partial<NotificationSettings> }
                : DEFAULT_SETTINGS;

            if (!settings.emailPengirim || !settings.passwordAplikasi || !settings.emailPenerima) {
                res.status(400).json({
                    success: false,
                    message: "Email settings not configured. Please set emailPengirim, passwordAplikasi, and emailPenerima in Firestore: settings/notifications",
                });
                return;
            }

            // Get all expiring employees (within 30 days)
            const usersSnapshot = await db.collection("users").get();
            const allExpiringEmployees: Array<Employee & { hariExpired: number }> = [];

            for (const userDoc of usersSnapshot.docs) {
                const employeesSnapshot = await db
                    .collection("users")
                    .doc(userDoc.id)
                    .collection("employees")
                    .get();

                for (const empDoc of employeesSnapshot.docs) {
                    const emp = empDoc.data() as Employee;
                    const hariExpired = hitungHariMenujuExpired(emp.tglPkwtBerakhir);

                    if (hariExpired >= 0 && hariExpired <= 30) {
                        allExpiringEmployees.push({ ...emp, hariExpired });
                    }
                }
            }

            if (allExpiringEmployees.length === 0) {
                res.json({
                    success: true,
                    message: "No employees with PKWT expiring within 30 days",
                });
                return;
            }

            // Sort and send
            allExpiringEmployees.sort((a, b) => a.hariExpired - b.hariExpired);

            const transporter = createEmailTransporter(settings);
            const emailHtml = createEmailTemplate(allExpiringEmployees);

            await transporter.sendMail({
                from: `"HR Dashboard" <${settings.emailPengirim}>`,
                to: settings.emailPenerima,
                subject: `🧪 [TEST] ${allExpiringEmployees.length} Karyawan dengan PKWT Segera Berakhir`,
                html: emailHtml,
            });

            res.json({
                success: true,
                message: `Test email sent to ${settings.emailPenerima}`,
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
