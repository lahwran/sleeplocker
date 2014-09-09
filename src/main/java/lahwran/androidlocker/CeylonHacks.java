// fucking ceylon java integration fucking sucks jesus fucking christ
//
package lahwran.androidlocker;

class CeylonHacks {
    static Class getPollalarmclass() {
        return PollingAlarmReceiver.class;
    }
    static Class getUnlockalarmclass() {
        return UnlockAlarmReceiver.class;
    }
    static Class getHardlockalarmclass() {
        return HardLockAlarmReceiver.class;
    }
    static Class getSoftlockalarmclass() {
        return SoftLockAlarmReceiver.class;
    }
}
