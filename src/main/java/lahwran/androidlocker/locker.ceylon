import android.app { Activity, AlarmManager, PendingIntent, ActivityManager }
import android.os { Bundle, SystemClock }
import android.content { Intent, Context, ComponentName, BroadcastReceiver }
import android.content.pm { PackageManager }
import android.app.admin { DevicePolicyManager, DeviceAdminReceiver }
import android.widget { Toast }
import android.view { View }
import android.util { Log }

import ceylon.interop.java { javaClass }

import ceylon.collection { HashMap }
import ceylon.time {
    // TODO: replace now(), today() with ntp-and-offset-based internal clock
    // to allow settings to be used again
    now, today, time,
    Time, Period, Instant
}
import ceylon.time.base {
    DayOfWeek,
    sunday, monday, tuesday, wednesday, thursday, friday, saturday
}

import java.lang { JavaString = String }


String logtag = "locker.ceylon";
ComponentName mAdminName = ComponentName("lahwran.androidlocker", "AdminReceiver");

class AccessList({<String->{String+}>+} initialValues)
        satisfies Category<ComponentName> {
    value contents = HashMap<String, {String+}>{
        entries=initialValues;
    };

    for (key->val in contents) {
        if ("*" in val) {
            assert(val.size == 1);
        }
    }

    shared actual Boolean contains(ComponentName obj) {
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

    // Can be used to change the time
    "com.android.settings" -> {
        "*"
        // TODO: need custom time system in order for this to be safe!
        //
        // // Can be used to uninstall or kill apps
        // "com.android.settings.Settings$ManageApplicationsActivity",
        // // Same as above
        // "com.android.settings.applications.InstalledAppDetails",
        // // Can be used to disable screen lock
        // "com.android.settings.ConfirmLockPassword",
        // // Can be used to disable device admins
        // "com.android.settings.DeviceAdminAdd"
    },

    // root manager - anything, this also disallows all root requests
    "eu.chainfire.supersu" -> {"*"},

    // commandline to which I give root.
    // therefore can be used to uninstall apps.
    "com.spartacusrex.spartacuside" -> {"*"},

    // play store - can be used to install un-blacklisted apps or uninstall apps
    "com.android.vending" -> {"*"},

    "com.estrongs.android.pop" -> {"*"}, // ES file manager

    "ru.org.amip.ClockSync" -> {"*"}
]);

AccessList miscblacklist = AccessList([
    // banned on weekdays! (well, except a couple of these
    //                      I need for work, so allowed during day)
    // mostly stuff I use for reddit/tumblr/etc.

    
    "com.google.android.youtube" -> {"*"},
    "com.tumblr" -> {"*"},
    "com.deeptrouble.yaarreddit" -> {"*"},
    "org.mozilla.firefox" -> {"*"},
    "com.android.chrome" -> {"*"},

    // misc:
    "com.google.android.googlequicksearchbox" -> {"*"},
    "com.rhmsoft.fm" -> {"*"}, // some random file manager
    "com.metago.astro" -> {"*"}, // astro file manager
    "ru.zdevs.zarchiver" -> {"*"},
    "com.spacemonkey.syncapp" -> {
        "com.spacemonkey.syncapp.myfiles.UploadFileActivity"
    },
    "com.google.android.apps.plus" -> {
        "com.google.android.apps.plus.phone.VideoViewActivity",
        "com.google.android.apps.plus.phone.HostPhotoViewIntentActivity"
    },
    "com.pearlmoon.android.media.AstiMediaPlayer" -> {"*"},
    "org.videolan.vlc.betav7neon" -> {
        "org.videolan.vlc.betav7neon.gui.video.VideoPlayerActivity"
    },
    "com.google.android.gallery3d" -> {"*"}
]);

AccessList morningwhitelist = AccessList([
    "com.google.android.music" -> {"*"}
]);

AccessList whitelist = AccessList([
    // tentative:
    "com.google.zxing.client.android" -> {"*"},
    "com.google.android.calendar" -> {"*"},
    "com.google.android.deskclock" -> {"*"},
    "com.spectrl.DashLight" -> {"*"},

    // weather (and news, but w/e, I don't even want to read that)
    "com.google.android.apps.genie.geniewidget" -> {"*"},
    "com.nestlabs.android" -> {"*"},

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

    "android" -> {"*"},
    "com.jamesmc.writer" -> {"*"},

    // whitelist:
    "com.android.settings" -> {
        "com.android.settings.SubSettings",
        "com.android.settings.Settings"
    },
    "com.mendhak.gpslogger" -> {"*"},
    "com.android.systemui" -> {"com.android.systemui.recent.RecentsActivity"},
    "com.teslacoilsw.launcher" -> {"*"},
    "com.google.android.dialer" -> {"*"},
    "com.google.android.apps.maps" -> {"*"},

    // includes emergency dialer
    "com.android.phone" -> {"*"},

    "com.google.android.gm" -> {"*"},
    "com.google.android.apps.googlevoice" -> {"*"},
    "com.google.android.GoogleCamera" -> {"*"},
    "info.staticfree.SuperGenPass" -> {"*"},
    "lahwran.androidlocker" -> {"*"}
]);

void toast(Context context, String message) {
    Toast.makeText(context, JavaString(message), Toast.\iLENGTH_SHORT).show();
    Log.v(logtag, "Toast message: ``message``");
}

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

Intent getSleepIntent(Context c) {
    return c.packageManager.getLaunchIntentForPackage("com.azumio.android.sleeptime");
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
abstract class Phase() {
    shared default Boolean poll = true;
    shared default Boolean enforce = true;
    shared formal Boolean allowed(ComponentName activity);
    shared formal Time start;
    shared default Intent(Context) getEnforceIntent = getSleepIntent;
}
interface Day {
    shared formal Time nextChange;
    shared formal Phase current;
}

object phases satisfies Day {
    // TODO: could use, like, TreeMap or something
    shared abstract class SequenceDay() satisfies Day {
        shared formal Phase day;
        shared formal Phase pretrigger;
        shared formal Phase evening;
        shared formal Phase night;
        shared formal Phase postwake;
        shared formal Phase morning;

        shared actual Time nextChange {
            value n = now().time();
            // reverse order
            if (n >= night.start) {
                return time(0, 10);
            } else if (n >= evening.start) {
                return night.start;
            } else if (n >= pretrigger.start) {
                return evening.start;
            } else if (n >= day.start) {
                return pretrigger.start;
            } else if (n >= postwake.start) {
                return day.start;
            } else {
                return postwake.start;
            }
        }

        shared actual Phase current {
            // TODO: geofencing. only night when at home?
            value n = now().time();
            // reverse order
            if (n >= night.start) {
                return night;
            } else if (n >= evening.start) {
                return evening;
            } else if (n >= pretrigger.start) {
                return pretrigger;
            } else if (n >= day.start) {
                return day;
            } else if (n >= postwake.start) {
                return postwake;
            } else {
                return morning;
            }
        }
    }
    shared object weekday extends SequenceDay() {
        string => "weekday";
        // don't you think it's cheating to just copy and paste it?
        shared actual object morning extends Phase() {
            string => "morning";
            allowed(ComponentName activity) => 
                (activity in whitelist || activity in morningwhitelist);
            start = time(0, 0);
        }
        shared actual object postwake extends Phase() {
            string => "evening";
            allowed(ComponentName activity) =>
                !(activity in blacklist
                  || activity in miscblacklist);
            start = time(5, 30);
            getEnforceIntent = getLauncherIntent;
        }
        shared actual object day extends Phase() {
            string => "day";
            poll = false;
            enforce = false;
            allowed(ComponentName activity) => true;
            start = time(9, 00);
        }
        shared actual object pretrigger extends Phase() {
            string => "pretrigger";
            enforce = false;
            allowed(ComponentName activity) => true;
            start = time(12 + 5, 00);
        }
        shared actual object evening extends Phase() {
            string => "evening";
            allowed(ComponentName activity) => !(activity in blacklist);
            start = time(12 + 5, 10);
            getEnforceIntent = getLauncherIntent;
        }
        shared actual object night extends Phase() {
            string => "night";
            allowed(ComponentName activity) => activity in whitelist;
            start = time(12 + 9, 0);
        }
    }
    shared object weekend extends SequenceDay() {
        string => "weekend";
        // don't you think it's cheating to just copy and paste it?
        shared actual object morning extends Phase() {
            string => "morning";
            allowed(ComponentName activity) => 
                (activity in whitelist || activity in morningwhitelist);
            start = time(0, 0);
            getEnforceIntent = getLauncherIntent;
        }
        shared actual object day extends Phase() {
            string => "day";
            poll = false;
            enforce = false;
            allowed(ComponentName activity) => true;
            start = time(7, 00);
        }
        postwake = day;
        shared actual object pretrigger extends Phase() {
            string => "pretrigger";
            enforce = false;
            allowed(ComponentName activity) => true;
            start = time(12 + 6, 0);
        }
        shared actual object evening extends Phase() {
            string => "evening";
            allowed(ComponentName activity) => !(activity in blacklist);
            start = time(12 + 6, 10);
            getEnforceIntent = getLauncherIntent;
        }
        shared actual object night extends Phase() {
            string => "night";
            allowed(ComponentName activity) => activity in whitelist;
            start = time(12 + 9, 0);
        }

    }
    shared Day today {
        DayOfWeek d = now().date().dayOfWeek;
        switch (d)
        case (monday, tuesday, wednesday, thursday, friday) {
            return weekday;
        }
        case (saturday, sunday) {
            return weekend;
        }
    }
    shared actual Time nextChange {
        return today.nextChange;
    }
    shared actual Phase current {
        return today.current;
    }
}

variable Boolean doLogging = false;
variable Integer lastPoll = 0;

Boolean logging {
    return doLogging && (lastPoll % 3 == 0);
}

shared class MainActivity() extends Activity() {
    shared actual void onCreate(Bundle? savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        if (phases.current.enforce) {
            setAlarms(this);
        }
    }

    shared void doLock(View view) {
        devicePolicyService(this).lockNow();
    }

    shared void enableAlarm(View view) {
        setAlarms(this);
        toast(this, "Enabled");
    }

    shared void disableAlarm(View view) {
        if (!phases.current.enforce) {
            removeAlarms(this);
        } else {
            toast(this, "No");
        }
    }

    shared void enableLogging(View view) {
        doLogging = true;
        setAlarms(this);
    }

    shared void disableLogging(View view) {
        doLogging = false;
        setAlarms(this);
    }

}

Integer timedelta(Integer delta) {
    return SystemClock.elapsedRealtime() + delta;
}

Instant nextInstanceOfTime(Time t) {
    value nowi = now();
    value todayi = today();
    variable value dt = todayi.at(t);
    if (dt.instant() < nowi) {
        dt = todayi.plus(Period {
            days = 1;
        }).at(t);
    }
    return dt.instant();
}

PendingIntent _broadcast<Receiver>(Context c)
        given Receiver satisfies BroadcastReceiver {
    return PendingIntent.getBroadcast(c, 0,
            Intent(c, javaClass<Receiver>()),
            PendingIntent.\iFLAG_UPDATE_CURRENT);
}

void setAlarms(Context c) {
    value currentphase = phases.current;
    value pollintent = _broadcast<PollingAlarmReceiver>(c);
    if (currentphase.poll || doLogging) {
        // would be nice to make this not exact, but the deltas can be too long
        // no wake, though, probably nbd
        alarmManager(c).set(AlarmManager.\iELAPSED_REALTIME,
                timedelta(1000), pollintent);
    } else {
        alarmManager(c).cancel(pollintent);
    }

    // does this need to be exact?
    value intent = _broadcast<ComeAliveReceiver>(c);
    value nc = phases.nextChange;
    value next = nextInstanceOfTime(nc);
    alarmManager(c).setExact(AlarmManager.\iRTC,
            next.millisecondsOfEpoch, intent);
}

void removeAlarms(Context c) {
    Log.d(logtag, "Removing all alarms");
    value intents = {
        _broadcast<PollingAlarmReceiver>(c),
        _broadcast<ComeAliveReceiver>(c)
    };
    for (pendingintent in intents) {
        alarmManager(c).cancel(pendingintent);
    }
}

shared class PollingAlarmReceiver() extends BroadcastReceiver() {
    shared actual void onReceive(Context context, Intent alarmintent) {
        lastPoll += 1;
        try {
            value taskInfo = activityManager(context).getRunningTasks(1); 
            value task = taskInfo.get(0);

            value phase = phases.current;

            if (phase.enforce && !phase.allowed(task.topActivity)) {
                toast(context, "Phase does not allow ``task.topActivity.flattenToString()``");
                value intent = phase.getEnforceIntent(context);
                intent.addFlags(Intent.\iFLAG_ACTIVITY_NEW_TASK);
                intent.addFlags(Intent.\iFLAG_ACTIVITY_REORDER_TO_FRONT);
                context.startActivity(intent);
            } else if (logging) {
                toast(context, "Current activity: ``task.topActivity.flattenToString()``");
            }
        } catch (Exception e) {
            Log.e(logtag, "error", e);
            if (doLogging) {
                toast(context, "Something blew up, see console");
            }
        }
        setAlarms(context);
    }
}

shared class ComeAliveReceiver() extends BroadcastReceiver() {
    shared actual void onReceive(Context context, Intent alarmintent) {
        Log.d(logtag, "Event time! ensuring alarms are set");
        setAlarms(context);
    }
}

shared class AdminReceiver() extends DeviceAdminReceiver() {
    shared actual void onEnabled(Context context, Intent intent) {
        toast(context, "enabled 1");
    }

    shared actual JavaString onDisableRequested(Context context, Intent intent) {
        toast(context, "disable request 1");
        return JavaString("derp derp");
    }

    shared actual void onDisabled(Context context, Intent intent) {
        toast(context, "disable 1");
    }
}
