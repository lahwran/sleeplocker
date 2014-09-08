import android.app { Activity, AlarmManager, PendingIntent, ActivityManager }
import android.os { Bundle, SystemClock }
import android.content { Intent, Context, ComponentName, BroadcastReceiver }
import android.content.pm { PackageManager }
import android.app.admin { DevicePolicyManager, DeviceAdminReceiver }
import android.widget { Toast }
import android.view { View }
import android.util { Log }

import java.lang { JavaString = String }


String logtag = "locker.ceylon";
ComponentName mAdminName = ComponentName("lahwran.androidlocker", "AdminReceiver");


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

        Log.d(logtag, "``getLauncherIntent(this)``");
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

void setAlarm(Context c) {
    value intent = Intent(c, CeylonHacks.alarmclass);
    value pendingintent = PendingIntent.getBroadcast(c, 0,
            intent, PendingIntent.\iFLAG_UPDATE_CURRENT);
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
        Log.d(logtag, "CURRENT Activity :: ``task.topActivity.flattenToString() else "null"`` - 
                       ``task.description else "null"`` - ``task.baseActivity.flattenToString() else "null"``");
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
