
# Benchmark



## System

Benchmark suite executing on the following system:

<table style="width: 1%">
  <tr>
    <th style="width: 1%; white-space: nowrap">Operating System</th>
    <td>Linux</td>
  </tr><tr>
    <th style="white-space: nowrap">CPU Information</th>
    <td style="white-space: nowrap">AMD Ryzen 5 1600 Six-Core Processor</td>
  </tr><tr>
    <th style="white-space: nowrap">Number of Available Cores</th>
    <td style="white-space: nowrap">12</td>
  </tr><tr>
    <th style="white-space: nowrap">Available Memory</th>
    <td style="white-space: nowrap">15.65 GB</td>
  </tr><tr>
    <th style="white-space: nowrap">Elixir Version</th>
    <td style="white-space: nowrap">1.13.4</td>
  </tr><tr>
    <th style="white-space: nowrap">Erlang Version</th>
    <td style="white-space: nowrap">24.2</td>
  </tr>
</table>

## Configuration

Benchmark suite executing with the following configuration:

<table style="width: 1%">
  <tr>
    <th style="width: 1%">:time</th>
    <td style="white-space: nowrap">5 s</td>
  </tr><tr>
    <th>:parallel</th>
    <td style="white-space: nowrap">1</td>
  </tr><tr>
    <th>:warmup</th>
    <td style="white-space: nowrap">2 s</td>
  </tr>
</table>

## Statistics




Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">db_1</td>
    <td style="white-space: nowrap; text-align: right">8.81 K</td>
    <td style="white-space: nowrap; text-align: right">113.48 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;11.19%</td>
    <td style="white-space: nowrap; text-align: right">113.93 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">151.22 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">holidefs_default_1</td>
    <td style="white-space: nowrap; text-align: right">8.44 K</td>
    <td style="white-space: nowrap; text-align: right">118.53 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;11.71%</td>
    <td style="white-space: nowrap; text-align: right">118.40 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">152.75 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">db_12</td>
    <td style="white-space: nowrap; text-align: right">4.09 K</td>
    <td style="white-space: nowrap; text-align: right">244.55 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;10.42%</td>
    <td style="white-space: nowrap; text-align: right">241.31 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">338.80 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">holidefs_default_12</td>
    <td style="white-space: nowrap; text-align: right">4.07 K</td>
    <td style="white-space: nowrap; text-align: right">245.42 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;9.91%</td>
    <td style="white-space: nowrap; text-align: right">243.49 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">334.61 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">db_24</td>
    <td style="white-space: nowrap; text-align: right">2.61 K</td>
    <td style="white-space: nowrap; text-align: right">382.90 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;10.58%</td>
    <td style="white-space: nowrap; text-align: right">374.25 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">575.09 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">holidefs_default_24</td>
    <td style="white-space: nowrap; text-align: right">2.61 K</td>
    <td style="white-space: nowrap; text-align: right">383.04 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;10.21%</td>
    <td style="white-space: nowrap; text-align: right">374.89 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">547.26 &micro;s</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">db_1</td>
    <td style="white-space: nowrap;text-align: right">8.81 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">holidefs_default_1</td>
    <td style="white-space: nowrap; text-align: right">8.44 K</td>
    <td style="white-space: nowrap; text-align: right">1.04x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">db_12</td>
    <td style="white-space: nowrap; text-align: right">4.09 K</td>
    <td style="white-space: nowrap; text-align: right">2.16x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">holidefs_default_12</td>
    <td style="white-space: nowrap; text-align: right">4.07 K</td>
    <td style="white-space: nowrap; text-align: right">2.16x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">db_24</td>
    <td style="white-space: nowrap; text-align: right">2.61 K</td>
    <td style="white-space: nowrap; text-align: right">3.37x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">holidefs_default_24</td>
    <td style="white-space: nowrap; text-align: right">2.61 K</td>
    <td style="white-space: nowrap; text-align: right">3.38x</td>
  </tr>

</table>



