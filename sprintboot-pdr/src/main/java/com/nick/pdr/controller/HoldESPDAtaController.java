package com.nick.pdr.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Date;

@RestController
public class HoldESPDAtaController {
    Integer times = 0;

    @PostMapping("/hello")
    public String hello(@RequestBody String params) {
        Date date = new Date();
        return date + "--->" + times++ + "--->" + params;
    }
    @PostMapping("/getESPdata")
    public String getESPdata(@RequestBody(required=false) String value) {
        System.out.println("Nick---------->" + value);
        return value;
    }
}
