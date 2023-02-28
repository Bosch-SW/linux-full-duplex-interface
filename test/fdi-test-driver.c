/*
 * This file contains a basic source code to test if the
 * full duplex interface header works.
 *
 * Copyright (c) 2023 Robert Bosch GmbH
 * Artem Gulyaev <Artem.Gulyaev@de.bosch.com>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// SPDX-License-Identifier: GPL-2.0

#include <linux/module.h>
#include <linux/printk.h>
#include <linux/slab.h>
#include <linux/full_duplex_interface.h>

/*------------------- SAMPLE INSERTION TEST DRIVER -----------------*/

int test_drv_data_xchange(void __kernel *device
                    , struct __kernel full_duplex_xfer *xfer
                    , bool force_size_change)
{
    printk("fdi-test-driver.data-exchange: PASS\n");
    return 0;
}

struct full_duplex_sym_iface  the_interface = {
    &test_drv_data_xchange, NULL, NULL, NULL, NULL, NULL };

__maybe_unused
static int __init docker_build_image_test_driver_init(void)
{

    the_interface.data_xchange(NULL, NULL, false);
	printk("fdi-test-driver.insmod: PASS\n");
	return 0;
}

__maybe_unused
static void __exit docker_build_image_test_driver_exit(void)
{
	printk("fdi-test-driver.rmmod: PASS\n");
}

/* --------------------- MODULE HOUSEKEEPING SECTION ------------------- */

module_init(docker_build_image_test_driver_init);
module_exit(docker_build_image_test_driver_exit);

MODULE_DESCRIPTION("Docker external linux modules build image test driver.");
MODULE_AUTHOR("Artem Gulyaev <Artem.Gulyaev@bosch.com>");
MODULE_LICENSE("GPL v2");
