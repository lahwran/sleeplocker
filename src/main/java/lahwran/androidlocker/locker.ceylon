import android.app { Activity }
import android.os { Bundle }
import android.content { Intent, Context, ComponentName }
import android.app.admin { DevicePolicyManager, DeviceAdminReceiver }
import android.widget { Toast }

import java.lang { JavaString = String }


ComponentName mAdminName = ComponentName("lahwran.androidlocker", "ReceiverThing");

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

    //shared void do

}

shared class ReceiverThing() extends DeviceAdminReceiver() {
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
