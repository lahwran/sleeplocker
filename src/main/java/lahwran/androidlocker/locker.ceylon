import android.app { Activity, AlarmManager, PendingIntent, ActivityManager }
import android.os { Bundle }
import android.content { Intent, Context, ComponentName, BroadcastReceiver }
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

shared class MainActivity() extends Activity() {
    shared actual void onCreate(Bundle? savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);


        value intent = Intent(DevicePolicyManager.\iACTION_ADD_DEVICE_ADMIN);
        intent.setFlags(Intent.\iFLAG_ACTIVITY_NEW_TASK);
        intent.putExtra(DevicePolicyManager.\iEXTRA_DEVICE_ADMIN, mAdminName);
        intent.putExtra(DevicePolicyManager.\iEXTRA_ADD_EXPLANATION,  "some text.");
        startActivity(intent);
    }

    shared void doLock(View view) {
        devicePolicyService(this).lockNow();
    }

    shared void enableAlarm(View view) {
        value intent = Intent(this, CeylonHacks.alarmclass);
        value pendingintent = PendingIntent.getBroadcast(this, 0,
                intent, PendingIntent.\iFLAG_UPDATE_CURRENT);
        alarmManager(this).setRepeating(AlarmManager.\iELAPSED_REALTIME_WAKEUP,
                1000, 1000, pendingintent);
    }

    shared void disableAlarm(View view) {
        value intent = Intent(this, CeylonHacks.alarmclass);
        value pendingintent = PendingIntent.getBroadcast(this, 0,
                intent, PendingIntent.\iFLAG_UPDATE_CURRENT);
        alarmManager(this).cancel(pendingintent);
    }

}

shared class AlarmReceiver() extends BroadcastReceiver() {
    shared actual void onReceive(Context context, Intent intent) {
        value taskInfo = activityManager(context).getRunningTasks(1); 
        Log.d(logtag, "CURRENT Activity ::"
                            + taskInfo.get(0).topActivity.className);
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
