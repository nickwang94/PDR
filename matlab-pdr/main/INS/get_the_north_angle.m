function angle = get_the_north_angle(data_mag, data_acc)
    a_x = data_acc(1,1);
    a_y = data_acc(2,1);
    a_z = data_acc(3,1);
    m_x = data_mag(1,1);
    m_y = data_mag(2,1);
    m_z = data_mag(3,1);
    
    p = atan(a_x/power((a_y^2+a_z^2),0.5));
    r = atan(a_y/power((a_x^2+a_z^2),0.5));
    
    m_hx = m_x*cos(p) + m_z*sin(p);
    m_hy = m_x*sin(r)*sin(p) + m_y*cos(r) - m_z*sin(r)*cos(p);
    
    if(m_hx > 0)
        if(m_hy >= 0)
            angle = atan(m_hy/m_hx) * (180/pi);
        else
            angle = 360 + atan(m_hy/m_hx) * (180/pi);
        end
    end
    
    if(m_hx < 0)
        angle = 180 + atan(m_hy/m_hx) * (180/pi);
    end
    
     if(m_hx == 0)
        if(m_hy < 0)
            angle = 90;
        else
            angle = 270;
        end
     end
     angle = deg2rad(angle);
end