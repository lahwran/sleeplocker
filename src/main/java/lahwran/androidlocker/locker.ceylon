import android.app { Activity, AlarmManager, PendingIntent, ActivityManager }
import android.os { Bundle, SystemClock }
import android.content { Intent, Context, ComponentName, BroadcastReceiver }
import android.content.pm { PackageManager }
import android.app.admin { DevicePolicyManager, DeviceAdminReceiver }
import android.widget { Toast }
import android.view { View }
import android.util { Log }

import ceylon.collection { HashMap }
import ceylon.time { now, today, time, Time, Period }

import java.lang { JavaString = String }


String logtag = "locker.ceylon";
ComponentName mAdminName = ComponentName("lahwran.androidlocker", "AdminReceiver");

class AccessList({Entry<String,{String+}>+} initialValues) satisfies Category {
    value contents = HashMap<String, {String+}>{
        entries=initialValues;
    };

    for (key->val in contents) {
        if ("*" in val) {
            assert(val.size == 1);
        }
    }

    shared actual Boolean contains(Object obj) {
        if (!obj is ComponentName) {
            return false;
        }
        assert(is ComponentName obj);

        value allowedClasses = contents[obj.packageName];
        if (!allowedClasses exists) {
            return false;
        }
        assert(exists allowedClasses);

        if ("*" in allowedClasses) {
            return true;
        }
        return obj.className in allowedClasses;
    }
}

AccessList blacklist = AccessList([
    // anything related to uninstalling
    "com.android.packageinstaller" -> {"*"},

    "com.android.settings" -> [
        // Can be used to uninstall or kill apps
        "com.android.settings.Settings$ManageApplicationsActivity",
        // Same as above
        "com.android.settings.applications.InstalledAppDetails",
        // Can be used to disable screen lock
        "com.android.settings.ConfirmLockPassword",
        // Can be used to disable device admins
        "com.android.settings.DeviceAdminAdd"
    ],

    // root manager - anything, this also disallows all root requests
    "eu.chainfire.supersu" -> {"*"},

    // commandline to which I give root.
    // therefore can be used to uninstall apps.
    "com.spartacusrex.spartacuside" -> {"*"},

    // play store - can be used to install un-blacklisted apps or uninstall apps
    "com.android.vending" -> {"*"},

    // File managers - could be used (especially with root) to delete
    // the app
    "com.estrongs.android.pop" -> {"*"}, // ES file manager
    "com.rhmsoft.fm" -> {"*"}, // some random file manager
    "com.metago.astro" -> {"*"} // astro file manager
]);

AccessList whitelist = AccessList([
    // tentative:
    "com.google.zxing.client.android" -> {"*"},
    "com.google.android.calendar" -> {"*"},
    "com.google.android.deskclock" -> {"*"},
    "com.spectrl.DashLight" -> {"*"},

    // google goggles
    "com.google.android.apps.unveil" -> {"*"},

    "com.mictale.gpsessentials" -> {"*"},
    "com.eclipsim.gpsstatus2" -> {"*"},
    "com.chartcross.gpstest" -> {"*"},
    "com.vito.lux" -> {"*"},
    "com.myfitnesspal.android" -> {"*"},
    "name.neerajkumar.mobile.android.notepad" -> {"*"},
    "com.android.contacts" -> {"*"},

    // not sure about the photos app... maybe?
    //"com.google.android.apps.plus" -> {"com.google.android.apps.photos.phone.PhotosHomeActivity"},

    "com.Slack" -> {"*"},
    "com.urbandroid.sleep" -> {"*"},
    "com.azumio.android.sleeptime" -> {"*"},
    "com.andrwq.recorder" -> {"*"},
    "com.wolfram.android.alpha" -> {"*"},
    "com.google.android.apps.translate" -> {"*"},
    "eu.ebak.silent_mobile" -> {"*"},

    "android" -> {"com.android.internal.app.ChooserActivity"},
    "com.jamesmc.writer" -> {"*"},

    // whitelist:
    "com.android.settings" -> {
        "com.android.settings.SubSettings",
        "com.android.settings.Settings"
    },
    "com.mendhak.gpslogger" -> {"*"},
    "com.android.systemui" -> {"com.android.systemui.recent.RecentsActivity"},
    "com.teslacoilsw.launcher" -> {"*"},
    "com.google.android.googlequicksearchbox" -> {"*"},
    "com.google.android.dialer" -> {"*"},

    // includes emergency dialer
    "com.android.phone" -> {"*"},

    "com.google.android.apps.googlevoice" -> {"*"},
    "com.google.android.GoogleCamera" -> {"*"},
    "info.staticfree.SuperGenPass" -> {"*"}
]);


AlarmManager alarmManager(Context c) {
    assert(is AlarmManager
            service = c.getSystemService(Context.\iALARM_SERVICE));
    return service;
}
DevicePolicyManager devicePolicyService(Context c) {
    assert(is DevicePolicyManager
            service = c.getSystemService(Context.\iDEVICE_POLICY_SERVICE));
    return service;
}
ActivityManager activityManager(Context c) {
    assert(is ActivityManager
            service = c.getSystemService(Context.\iACTIVITY_SERVICE));
    return service;
}

Intent getLauncherIntent(Context c) {
    value activities = c.packageManager.queryIntentActivities(
            Intent(Intent.\iACTION_MAIN)
                .addCategory(Intent.\iCATEGORY_HOME),
            PackageManager.\iMATCH_DEFAULT_ONLY);
    variable Intent? result = null;
    for(index in 0:activities.size()) {
        value resolveInfo = activities.get(index);
        Log.d(logtag, resolveInfo.activityInfo.packageName);
        result = c.packageManager.getLaunchIntentForPackage(resolveInfo.activityInfo.packageName);
    }
    Intent? intent = result;
    assert(exists intent);
    return intent;
}

shared class MainActivity() extends Activity() {
    shared actual void onCreate(Bundle? savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

    }

    shared void doLock(View view) {
        devicePolicyService(this).lockNow();
    }

    shared void enableAlarm(View view) {
        setAlarm(this);
    }

    shared void disableAlarm(View view) {
        removeAlarm(this);
    }

}

Integer timedelta(Integer delta) {
    return SystemClock.elapsedRealtime() + delta;
}

Integer nextInstanceOfTime(Time t) {
    value nowi = now();
    value todayi = today();
    variable value dt = todayi.at(t);
    if (dt.instant() < nowi) {
        dt = todayi.plus(Period {
            days = 1;
        }).at(t);
    }
    return dt.instant().millisecondsOfEpoch;
}

void setAlarm(Context c) {
    value intent = Intent(c, CeylonHacks.alarmclass);
    value pendingintent = PendingIntent.getBroadcast(c, 0,
            intent, PendingIntent.\iFLAG_UPDATE_CURRENT);
    alarmManager(c).cancel(pendingintent);
    alarmManager(c).setExact(AlarmManager.\iELAPSED_REALTIME_WAKEUP,
            timedelta(1000), pendingintent);
}

void removeAlarm(Context c) {
    value intent = Intent(c, CeylonHacks.alarmclass);
    value pendingintent = PendingIntent.getBroadcast(c, 0,
            intent, PendingIntent.\iFLAG_UPDATE_CURRENT);
    alarmManager(c).cancel(pendingintent);
}

shared class AlarmReceiver() extends BroadcastReceiver() {
    shared actual void onReceive(Context context, Intent alarmintent) {
        value taskInfo = activityManager(context).getRunningTasks(1); 
        value task = taskInfo.get(0);
        value blacklisted = task.topActivity in blacklist then "blacklisted" else "not blacklisted";
        value whitelisted = task.topActivity in whitelist then "whitelisted" else "not whitelisted";
        Log.d(logtag, "``blacklisted``, ``whitelisted``: ``task.topActivity.flattenToString()``");
        if (task.topActivity.flattenToString() == "com.android.systemui/com.android.systemui.recent.RecentsActivity") {
            value intent = getLauncherIntent(context);
            intent.addFlags(Intent.\iFLAG_ACTIVITY_NEW_TASK);
            intent.addFlags(Intent.\iFLAG_ACTIVITY_REORDER_TO_FRONT);
            context.startActivity(intent);
        }
        setAlarm(context);
    }
}

shared class AdminReceiver() extends DeviceAdminReceiver() {
    shared actual void onEnabled(Context context, Intent intent) {
        Toast.makeText(context, JavaString("enabled 1"), Toast.\iLENGTH_SHORT).show();
    }

    shared actual JavaString onDisableRequested(Context context, Intent intent) {
        Toast.makeText(context, JavaString("disable request 1"), Toast.\iLENGTH_SHORT).show();
        return JavaString("derp derp");
    }

    shared actual void onDisabled(Context context, Intent intent) {
        Toast.makeText(context, JavaString("disable 1"), Toast.\iLENGTH_SHORT).show();
    }
}
