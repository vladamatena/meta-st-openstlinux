FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS += "${@oe.utils.conditional('DISTRO_FEATURES', 'pulseaudio', 'pulseaudio', '', d)}"

SRC_URI += " \
            file://weston.ini \
            file://utilities-terminal.png \
            file://ST_1366x768.png \
            file://OpenSTLinux_background_1024x600.png \
            file://ST13345_Products_light_blue_24x24.png \
            file://space.png \
            file://weston-checkgpu.service \
            file://weston_profile.sh \
            file://README-CHECK-GPU \
            file://72-galcore.rules \
            \
            file://73-pulseaudio-hdmi.rules \
            file://default_pulseaudio_profile \
            file://pulseaudio_hdmi_switch.sh \
            \
            file://weston-graphical-session.service \
            file://systemd-graphical-weston-session.sh \
            file://weston.service \
            file://weston.socket \
            "
SRC_URI:append:stm32mpcommon = " file://check-gpu "

FILES:${PN} += " ${datadir}/weston \
         ${sysconfdir}/etc/default \
         ${systemd_system_unitdir}/weston-launch.service \
         ${sbindir}/ \
         ${sysconfdir}/etc/default \
         ${sysconfdir}/etc/profile.d \
         ${sysconfdir}/xdg/weston/weston.ini \
         /home/root \
         ${systemd_user_unitdir} \
         "

CONFFILES:${PN} += "${sysconfdir}/xdg/weston/weston.ini"

do_install:append() {
    install -d ${D}${sysconfdir}/xdg/weston/
    install -d ${D}${datadir}/weston/backgrounds
    install -d ${D}${datadir}/weston/icon

    install -m 0644 ${WORKDIR}/weston.ini ${D}${sysconfdir}/xdg/weston

    install -m 0644 ${WORKDIR}/utilities-terminal.png ${D}${datadir}/weston/icon/utilities-terminal.png
    install -m 0644 ${WORKDIR}/ST13345_Products_light_blue_24x24.png ${D}${datadir}/weston/icon/ST13345_Products_light_blue_24x24.png
    install -m 0644 ${WORKDIR}/ST_1366x768.png ${D}${datadir}/weston/backgrounds/ST_1366x768.png
    install -m 0644 ${WORKDIR}/OpenSTLinux_background_1024x600.png ${D}${datadir}/weston/backgrounds/OpenSTLinux_background_1024x600.png

    install -m 0644 ${WORKDIR}/space.png ${D}${datadir}/weston/icon/

    install -d ${D}${systemd_system_unitdir} ${D}${sbindir}

    install -d ${D}/${systemd_system_unitdir}
    if [ -e ${D}${systemd_system_unitdir}/weston.service ]; then
        rm ${D}${systemd_system_unitdir}/weston.service ${D}${systemd_system_unitdir}/weston.socket
        install -D -p -m0644 ${WORKDIR}/weston-graphical-session.service ${D}${systemd_system_unitdir}/weston-graphical-session.service
        sed -i -e s:/etc:${sysconfdir}:g \
            -e s:/usr/bin:${bindir}:g \
            -e s:/var:${localstatedir}:g \
            ${D}${systemd_unitdir}/system/weston-graphical-session.service
        install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants/
        install -D -m 0755 ${WORKDIR}/systemd-graphical-weston-session.sh ${D}${bindir}/systemd-graphical-weston-session.sh
        #ln -s /lib/systemd/system/weston-launch.service ${D}${sysconfdir}/systemd/system/multi-user.target.wants/display-manager.service
        install -D -p -m0644 ${WORKDIR}/weston-checkgpu.service ${D}${systemd_system_unitdir}/weston-checkgpu.service

        install -d ${D}${systemd_user_unitdir}
        install -D -p -m0644 ${WORKDIR}/weston.service ${D}${systemd_user_unitdir}/weston.service
        install -D -p -m0644 ${WORKDIR}/weston.socket ${D}${systemd_user_unitdir}/weston.socket
    fi

    install -d ${D}${sysconfdir}/profile.d
    install -m 0755 ${WORKDIR}/weston_profile.sh ${D}${sysconfdir}/profile.d/

    if ${@bb.utils.contains('DISTRO_FEATURES','xwayland','true','false',d)}; then
        # uncomment modules line for support of xwayland
        sed -i -e 's,#xwayland=true,xwayland=true,g' ${D}${sysconfdir}/xdg/weston/weston.ini
    fi

    install -Dm755 ${WORKDIR}/weston-start ${D}${bindir}/weston-start
    sed -i 's,@DATADIR@,${datadir},g' ${D}${bindir}/weston-start
    sed -i 's,@LOCALSTATEDIR@,${localstatedir},g' ${D}${bindir}/weston-start

    # /etc/default/weston
    install -d ${D}${sysconfdir}/default
    echo "WESTON_USER=weston" > ${D}${sysconfdir}/default/weston

    # check GPU
    install -d ${D}/home/root/
    install -m 644 ${WORKDIR}/README-CHECK-GPU ${D}/home/root/
    if ! test -f ${D}${base_sbindir}/check-gpu; then
        install -d ${D}${base_sbindir}
        echo '#!/bin/sh' > ${WORKDIR}/check-gpu.empty
        echo '/bin/true' >> ${WORKDIR}/check-gpu.empty
        install -m 755 ${WORKDIR}/check-gpu.empty ${D}${base_sbindir}/check-gpu
    fi

    # udev rules for galcore
    install -D -p -m0644 ${WORKDIR}/72-galcore.rules ${D}${sysconfdir}/udev/rules.d/72-galcore.rules

    # AUDIO: swith between analog stero and HDMI
    install -d ${D}${sysconfdir}/default
    install -m 0644 ${WORKDIR}/default_pulseaudio_profile ${D}${sysconfdir}/default/pulseaudio_profile
    install -d ${D}${sysconfdir}/udev/rules.d
    install -p -m 0644 ${WORKDIR}/73-pulseaudio-hdmi.rules ${D}${sysconfdir}/udev/rules.d/73-pulseaudio-hdmi.rules
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/pulseaudio_hdmi_switch.sh ${D}${bindir}/
}

do_install:append:stm32mpcommon() {
    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${base_sbindir}
        install -m 755 ${WORKDIR}/check-gpu ${D}${base_sbindir}
    fi
}

SYSTEMD_SERVICE:${PN}:remove = "weston.service weston.socket"
SYSTEMD_SERVICE:${PN} += "weston-graphical-session.service weston-checkgpu.service"
#inherit useradd
USERADD_PARAM:${PN} = "--home /home/weston --shell /bin/sh --user-group -G video,input,tty,audio,dialout weston"
GROUPADD_PARAM:${PN} = "-r wayland"
